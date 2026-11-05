#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

[[ -n "${PREFIX:-}" && "$PREFIX" == *com.termux* ]] || fail "Run this script inside the Termux app."
case "$(uname -m)" in
  aarch64|arm64) ;;
  *) fail "This setup script currently targets ARM64 Android devices." ;;
esac

printf '%s\n' "This will install Kali NetHunter Rootless using the official Kali installer."
printf '%s\n' "It needs several GB of free storage and a stable internet connection."
read -r -p "Continue? [y/N] " answer
[[ "$answer" == [yY] || "$answer" == [yY][eE][sS] ]] || exit 0

pkg update -y
pkg upgrade -y
pkg install -y wget proot tar

INSTALLER="$HOME/install-nethunter-termux"
wget -O "$INSTALLER" "https://offs.ec/2MceZWr"
chmod 700 "$INSTALLER"

printf '\n%s\n' "Launching the official Kali NetHunter Rootless installer..."
printf '%s\n' "Follow its prompts. Do not close Termux while the rootfs is downloading."
exec "$INSTALLER"
