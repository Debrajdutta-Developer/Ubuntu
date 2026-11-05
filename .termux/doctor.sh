#!/data/data/com.termux/files/usr/bin/bash
set -u

printf '%s\n' "=== Termux / Kali diagnostic ==="
printf 'Architecture: '; uname -m
printf 'Android kernel: '; uname -r
printf 'Termux prefix: %s\n' "${PREFIX:-not detected}"
printf 'Free storage: '; df -h "$HOME" | awk 'NR==2 {print $4 " available"}'

if command -v nethunter >/dev/null 2>&1; then
  printf 'NetHunter command: %s\n' "$(command -v nethunter)"
elif command -v nh >/dev/null 2>&1; then
  printf 'NetHunter command: %s\n' "$(command -v nh)"
else
  printf '%s\n' "NetHunter command: NOT FOUND (installation may not be complete)"
fi

if command -v nethunter >/dev/null 2>&1; then
  printf '\n%s\n' "Kali release:"
  nethunter cat /etc/os-release 2>/dev/null | sed -n '1,6p' || true
fi
