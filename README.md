# Ubuntu / Kali on Android (Termux-first)

This repository now documents a **local Android workflow**. GitHub Codespaces is optional and is not required.

## Target setup

- Android + Termux (ARM64)
- Official Kali NetHunter Rootless userspace
- Kali CLI in Termux
- Optional Kali desktop through the official NetHunter KeX client

> Rootless NetHunter does not give Android root access. Some hardware-dependent features are unavailable. Keep several GB of free storage and use a stable Wi-Fi connection for the initial download.

## 1. Install Kali from Termux

Open Termux and run:

```bash
pkg update -y && pkg upgrade -y
pkg install -y git
git clone https://github.com/Debrajdutta-Developer/Ubuntu.git
cd Ubuntu
bash .termux/install-nethunter.sh
```

The installer downloads and runs the official Kali NetHunter Rootless installer documented by Kali:
https://www.kali.org/docs/nethunter/nethunter-rootless/

## 2. Start Kali

After installation:

```bash
nh
```

Update Kali from inside its shell:

```bash
sudo apt update
sudo apt full-upgrade -y
```

## 3. Optional desktop (KeX)

Install the NetHunter KeX client from the official NetHunter Store. Then, in Termux:

```bash
nh kex passwd
nh kex &
```

Open the KeX client, enter the password you just created, and connect. To stop the desktop:

```bash
nh kex stop
```

Use the normal user session unless you have a specific administrative need. Root mode in a proot container is not Android device root.

## 4. Quick diagnostics

From Termux, run:

```bash
bash .termux/doctor.sh
```

## Notes

- This is a local setup; no Codespace, cloud VM, or paid server is involved.
- The first Kali rootfs download is large and can take time.
- Do not run random install scripts from untrusted sources.
- The `.devcontainer/` directory remains for anyone who separately wants a Codespace. It is not used by the Termux workflow.
