#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

LOG_DIR="/var/log/kali-desktop"
mkdir -p "$LOG_DIR" /root/.vnc /tmp/.X11-unix
exec > >(tee -a "$LOG_DIR/startup.log") 2>&1

log() { printf '[%s] %s\n' "$(date -Is)" "$*"; }
fail() { log "ERROR: $*"; exit 1; }

export HOME=/root
export USER=root
export DISPLAY=:1
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=XFCE

VNC_PID=""
NOVNC_PID=""

cleanup() {
  log "Stopping desktop services."
  [[ -n "$NOVNC_PID" ]] && kill "$NOVNC_PID" 2>/dev/null || true
  tightvncserver -kill :1 >/dev/null 2>&1 || true
  service postgresql stop >/dev/null 2>&1 || true
}
trap cleanup EXIT
trap 'exit 0' INT TERM
trap 'fail "Startup failed at line $LINENO (exit $?)."' ERR

log "Starting Kali Codespaces environment."

# PostgreSQL cluster recovery and service startup.
if ! pg_lsclusters --no-header | awk '$2 == "main" { found=1 } END { exit !found }'; then
  PG_MAJOR="$(pg_config --version | awk '{print $2}' | cut -d. -f1)"
  pg_createcluster "$PG_MAJOR" main
fi
service postgresql start
pg_lsclusters

# Create or update the application role and database idempotently.
DB_PASSWORD="${KALI_DB_PASSWORD:-}"
if [[ -z "$DB_PASSWORD" ]]; then
  if [[ -s /root/.kali-db-password ]]; then
    DB_PASSWORD="$(cat /root/.kali-db-password)"
  else
    DB_PASSWORD="$(openssl rand -hex 24)"
    printf '%s' "$DB_PASSWORD" > /root/.kali-db-password
    chmod 0600 /root/.kali-db-password
  fi
fi

runuser -u postgres -- psql -v ON_ERROR_STOP=1 --set=db_password="$DB_PASSWORD" <<'SQL'
SELECT format('CREATE ROLE kaliadmin LOGIN PASSWORD %L', :'db_password')
WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'kaliadmin')\gexec
SELECT format('ALTER ROLE kaliadmin WITH LOGIN PASSWORD %L', :'db_password')\gexec
SELECT 'CREATE DATABASE kalidev OWNER kaliadmin'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'kalidev')\gexec
ALTER DATABASE kalidev OWNER TO kaliadmin;
SQL
unset DB_PASSWORD
log "PostgreSQL ready: database=kalidev user=kaliadmin."
log "Database password is stored in /root/.kali-db-password (root-only)."

# Remove stale X11/VNC state and prepare a private VNC password.
tightvncserver -kill :1 >/dev/null 2>&1 || true
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1
chmod 1777 /tmp/.X11-unix

VNC_PASSWORD="${KALI_VNC_PASSWORD:-}"
if [[ -z "$VNC_PASSWORD" ]]; then
  if [[ -s /root/.vnc-password ]]; then
    VNC_PASSWORD="$(cat /root/.vnc-password)"
  else
    VNC_PASSWORD="$(openssl rand -hex 4)"
    printf '%s' "$VNC_PASSWORD" > /root/.vnc-password
    chmod 0600 /root/.vnc-password
  fi
fi

printf '%s\n' "$VNC_PASSWORD" | tigervncpasswd -f > /root/.vnc/passwd
chmod 0600 /root/.vnc/passwd
unset VNC_PASSWORD

# Disable XFCE compositing before the session starts for smoother browser VNC.
mkdir -p /root/.config/xfce4/xfconf
cat > /root/.config/xfce4/xfconf/xfwm4.xml <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="use_compositing" type="bool" value="false"/>
  </property>
</channel>
XML

cat > /root/.vnc/xstartup <<'XSTARTUP'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=XFCE
export DISPLAY=:1
exec dbus-launch --exit-with-session startxfce4
XSTARTUP
chmod 0755 /root/.vnc/xstartup

log "Launching XFCE desktop on VNC display :1."
tightvncserver :1 -geometry 1280x720 -depth 24 -localhost yes

# Wait until the VNC server accepts local connections.
for attempt in $(seq 1 30); do
  if timeout 1 bash -c '</dev/tcp/127.0.0.1/5901' 2>/dev/null; then
    break
  fi
  sleep 1
done
timeout 2 bash -c '</dev/tcp/127.0.0.1/5901' 2>/dev/null || fail "VNC did not start on port 5901."

NOVNC_PROXY="$(command -v novnc_proxy || true)"
if [[ -z "$NOVNC_PROXY" ]]; then
  for candidate in /usr/share/novnc/utils/novnc_proxy /usr/share/novnc/novnc_proxy; do
    if [[ -x "$candidate" ]]; then NOVNC_PROXY="$candidate"; break; fi
  done
fi
[[ -n "$NOVNC_PROXY" ]] || fail "novnc_proxy was not found."

log "Starting noVNC gateway on port 8080."
"$NOVNC_PROXY" --vnc localhost:5901 --listen 8080 >> "$LOG_DIR/novnc.log" 2>&1 &
NOVNC_PID=$!

for attempt in $(seq 1 30); do
  if timeout 1 bash -c '</dev/tcp/127.0.0.1/8080' 2>/dev/null; then
    break
  fi
  kill -0 "$NOVNC_PID" 2>/dev/null || fail "noVNC exited; inspect $LOG_DIR/novnc.log."
  sleep 1
done
timeout 2 bash -c '</dev/tcp/127.0.0.1/8080' 2>/dev/null || fail "noVNC did not listen on port 8080."

log "Kali desktop is ready. Open forwarded port 8080 in the Codespaces Ports tab."
log "VNC password is stored at /root/.vnc-password; read it from the Codespace terminal."
log "VNC is bound to localhost only; port 5901 is not exposed publicly."

# Keep the container alive and fail clearly if either desktop service exits.
while true; do
  kill -0 "$NOVNC_PID" 2>/dev/null || fail "noVNC stopped unexpectedly."
  pgrep -x Xtigervnc >/dev/null 2>&1 || pgrep -x Xvnc >/dev/null 2>&1 || fail "VNC server stopped unexpectedly."
  sleep 10
done
