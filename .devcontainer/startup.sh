#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

LOG_DIR="/var/log/ubuntu-desktop"
mkdir -p "$LOG_DIR" "$HOME/.vnc" /tmp/.X11-unix
exec > >(tee -a "$LOG_DIR/startup.log") 2>&1

log() { printf '[%s] %s\n' "$(date -Is)" "$*"; }
fail() { log "ERROR: $*"; exit 1; }

export USER=codespace
export HOME=/workspaces/.cloud-home
export DISPLAY=:1
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=XFCE
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
mkdir -p "$HOME" "$HOME/.vnc" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
chmod 0700 "$HOME" "$HOME/.vnc"

NOVNC_PID=""

cleanup() {
  log "Stopping desktop services."
  [[ -n "$NOVNC_PID" ]] && kill "$NOVNC_PID" 2>/dev/null || true
  tigervncserver -kill :1 >/dev/null 2>&1 || true
}
trap cleanup EXIT
trap 'exit 0' INT TERM
trap 'fail "Startup failed at line $LINENO (exit $?)."' ERR

log "Starting Ubuntu 24.04 XFCE Codespaces desktop."

# Remove stale X11/VNC state before starting a fresh desktop session.
tigervncserver -kill :1 >/dev/null 2>&1 || true
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1
chmod 1777 /tmp/.X11-unix

# Generate a private VNC password once and keep it in the persistent workspace
# home. TigerVNC's classic password file uses the first eight characters.
if [[ ! -s "$HOME/.vnc-password" ]]; then
  openssl rand -hex 4 > "$HOME/.vnc-password"
  chmod 0600 "$HOME/.vnc-password"
fi
tigervncpasswd -f < "$HOME/.vnc-password" > "$HOME/.vnc/passwd"
chmod 0600 "$HOME/.vnc/passwd"

# Disable XFCE compositing for smoother rendering over a browser VNC session.
mkdir -p "$XDG_CONFIG_HOME/xfce4/xfconf"
cat > "$XDG_CONFIG_HOME/xfce4/xfconf/xfwm4.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="use_compositing" type="bool" value="false"/>
  </property>
</channel>
XML

cat > "$HOME/.vnc/xstartup" <<'XSTARTUP'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=XFCE
export DISPLAY=:1
exec dbus-launch --exit-with-session startxfce4
XSTARTUP
chmod 0755 "$HOME/.vnc/xstartup"

log "Launching XFCE on VNC display :1."
tigervncserver :1 -geometry 1600x900 -depth 24 -localhost yes

for attempt in $(seq 1 40); do
  if timeout 1 bash -c '</dev/tcp/127.0.0.1/5901' 2>/dev/null; then break; fi
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

log "Starting private noVNC gateway on port 8080."
"$NOVNC_PROXY" --vnc localhost:5901 --listen 8080 >> "$LOG_DIR/novnc.log" 2>&1 &
NOVNC_PID=$!

for attempt in $(seq 1 40); do
  if timeout 1 bash -c '</dev/tcp/127.0.0.1/8080' 2>/dev/null; then break; fi
  kill -0 "$NOVNC_PID" 2>/dev/null || fail "noVNC exited; inspect $LOG_DIR/novnc.log."
  sleep 1
done
timeout 2 bash -c '</dev/tcp/127.0.0.1/8080' 2>/dev/null || fail "noVNC did not listen on port 8080."

log "Ubuntu XFCE desktop is ready. Open forwarded port 8080 in the Codespaces Ports tab."
log "VNC password is stored in $HOME/.vnc-password; read it from the Codespace terminal."
log "Antigravity IDE launcher: antigravity-ide"
log "Persistent home: $HOME"
log "VNC listens on localhost only; do not expose port 5901 publicly."

while true; do
  kill -0 "$NOVNC_PID" 2>/dev/null || fail "noVNC stopped unexpectedly."
  pgrep -x Xtigervnc >/dev/null 2>&1 || pgrep -x Xvnc >/dev/null 2>&1 || fail "VNC server stopped unexpectedly."
  sleep 10
done
