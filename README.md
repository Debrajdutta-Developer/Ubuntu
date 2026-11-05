# Kali Linux Full GUI Environment

A GitHub Codespaces development machine built from the official Kali Rolling image, with XFCE desktop streamed to the browser through noVNC.

## What is included

- Kali Linux Rolling with `kali-linux-headless`
- XFCE4 desktop with compositing disabled for smoother browser rendering
- TigerVNC server on localhost port 5901, exposed through the compatible `tightvncserver` command
- noVNC + websockify browser gateway on port 8080
- Firefox ESR and Chromium
- PostgreSQL with database `kalidev` and role `kaliadmin`
- Git, Git LFS, curl, wget, Python 3, pip, venv, Node.js, npm, compiler toolchain and common utilities
- VS Code extensions installed by the Codespaces devcontainer configuration

## Start

1. Open this repository in GitHub Codespaces.
2. Wait for the dev container build and startup to finish.
3. In the Codespaces **Ports** tab, open port **8080**. It is configured as private and should auto-open in the browser.
4. Enter the VNC password when noVNC asks for it.

Read the generated VNC password in the Codespace terminal:

```bash
cat /root/.vnc-password
```

The PostgreSQL password is generated separately and stored root-only:

```bash
cat /root/.kali-db-password
```

Database connection details:

- Host: `127.0.0.1`
- Port: `5432`
- Database: `kalidev`
- User: `kaliadmin`

## Rebuild

After changing any file under `.devcontainer/`, run **Codespaces: Rebuild Container** from the VS Code web Command Palette. A full rebuild is only needed if the normal rebuild reuses a broken cached image.

## Security and operational notes

- VNC listens on localhost only. Do not expose port 5901 publicly.
- Port 8080 is configured as private in Codespaces.
- VNC authentication is enabled. No password bypass or shared hard-coded password is used.
- Password files are root-only and live inside the Codespace container.
- Codespaces is a cloud development environment, not an always-on server. Stopping/deleting the Codespace affects its compute lifecycle; keep important work committed and pushed to GitHub.
- Kali security tools must only be used on systems and networks you own or are explicitly authorized to test.
- Kali Rolling package versions change over time. The Docker build log is the source of truth if a package is renamed or temporarily unavailable.
