#!/usr/bin/env bash
set -Eeuo pipefail

LOG_DIR="/var/log/kali-desktop"
mkdir -p "$LOG_DIR" /root/.vnc
exec > >(tee -a "$LOG_DIR/startup.log") 2>&1

log() { printf '[%s] %s\n' "$(date -Is)" "$*"; }
fail() { log "ERROR: $*"; exit 1; }
trap 'fail "Startup failed at line $LINENO (exit $?)."' ERR

export HOME=/root
export USER=root
export DISPLAY=:1

log "Starting Kali Codespaces desktop services."

# Start PostgreSQL and ensure the default cluster is online.
if ! pg_lsclusters --no-header | grep -q .; then
  log "No PostgreSQL cluster found; creating the default cluster."
  PG_MAJOR="$(pg_config --version | awk '{print $2}' | cut -d. -f1)"
  pg_createcluster "$PG_MAJOR" main
fi
service postgresql start
pg_lsclusters

# Create an idempotent application role/database. The password is generated
# once and stored with root-only permissions unless supplied via environment.
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
export DB_PASSWORD
runuser -u postgres -- psql -v ON_ERROR_STOP=1 --set=db_password="$DB_PASSWORD" <<'SQL'
SELECT format('CREATE ROLE kaliadmin LOGIN PASSWORD %L', :'db_password')
WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'kaliadmin')\gexec
SELECT format('ALTER ROLE kaliadmin WITH LOGIN PASSWORD %L', :'db_password')\gexec
SELECT 'CREATE DATABASE kalidev OWNER kaliadmin'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'kalidev')\gexec
ALTER DATABASE kalidev OWNER TO kaliadmin;
SQL
unset DB_PASSWORD
log "PostgreSQL is ready (database: kalidev, role: kaliadmin)."

# Remove stale display locks before starting the VNC display.
tightvncserver -kill :1 >/dev/null 2>&1 || true
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1
mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

# VNC requires authentication. Use KALI_VNC_PASSWORD when supplied; otherwise
# generate a per-container password and write it to a root-only file.
VNC_PASSWORD="${KALI_VNC_PASSWORD:-}"
if [[ -z "$VNC_PASSWORD" ]]; then
  if [[ -s /root/.vnc-password ]]; then
    VNC_PASSWORD="$(cat /root/.vnc-password)"
  else
    VNC_PASSWORD="$(openssl rand -hex 8)"
    printf '%s' "$VNC_PASSWORD" > /root/.vnc-password
    chmod 0600 /root/.vnc-password
    log "Generated VNC password (shown once): $VNC_PASSWORD"
  fi
fi
install -d -m 0700 /root/.vnc
printf '%s\n' "$VNC_PASSWORD" | tigervncpasswd -f > /root/.vnc/passwd 2>/dev/null || \
  printf '%s\n' "$VNC_PASSWORD" | vncpasswd -f > /root/.vnc/passwd
chmod 0600 /root/.vnc/passwd
unset VNC_PASSWORD

cat > /root/.vnc/xstartup <<'XSTARTUP'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=XFCE
export DISPLAY=:1
# Disable XFCE window-manager compositing to reduce browser-stream overhead.
xfconf-query -c xfwm4 -p /general/use_compositing -n -t bool -s false 2>/dev/null || \
  xfconf-query -c xfwm4 -p /general/use_compositing -s false 2>/dev/null || true
exec dbus-launch --exit-with-session startxfce4
XSTARTUP
chmod 0755 /root/.vnc/xstartup

log "Launching XFCE on VNC display :1."
tightvncserver :1 -geometry 1280x720 -depth 24 -localhost yes

# Resolve the packaged noVNC proxy path across Kali package revisions.
NOVNC_PROXY="$(command -v novnc_proxy || true)"
if [[ -z "$NOVNC_PROXY" ]]; then
  for candidate in /usr/share/novnc/utils/novnc_proxy /usr/share/novnc/novnc_proxy; do
    if [[ -x "$candidate" ]]; then NOVNC_PROXY="$candidate"; break; fi
  done
fi
[[ -n "$NOVNC_PROXY" ]] || fail "novnc_proxy was not found after installing novnc."

log "Starting noVNC web gateway on port 8080."
"$NOVNC_PROXY" --vnc localhost:5901 --listen 8080 >> "$LOG_DIR/novnc.log" 2>&1 &
NOVNC_PID=$!

cleanup() {
  log "Stopping noVNC and VNC services."
  kill "$NOVNC_PID" 2>/dev/null || true
  tightvncserver -kill :1 >/dev/null 2>&1 || true
  service postgresql stop >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

# Keep the container alive while surfacing proxy failures in the main log.
while kill -0 "$NOVNC_PID" 2>/dev/null; do
  sleep 10
done
fail "noVNC proxy exited unexpectedly; inspect $LOG_DIR/novnc.log."
