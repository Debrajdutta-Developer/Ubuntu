# Ubuntu 24.04 XFCE + Google Antigravity Desktop

A GitHub Codespaces workstation based on Ubuntu 24.04 LTS. It streams a full XFCE desktop into a browser using TigerVNC and noVNC, with the official standalone Google Antigravity IDE installed in the image.

## Included

- Ubuntu 24.04 LTS (x86_64 Codespaces host)
- XFCE4 desktop, configured without compositing for smoother remote display
- TigerVNC bound to localhost only
- noVNC + websockify browser gateway on port 8080
- Google Antigravity standalone IDE for Linux x64
- Firefox from Mozilla's official Linux archive for browser-based sign-in
- Git, Git LFS, OpenSSH client, Python 3, pip, venv, Node.js, npm, compiler toolchain and common utilities
- Non-root `codespace` user
- Persistent home at `/workspaces/.cloud-home` so IDE settings and login state survive Codespaces container rebuilds

## Start the desktop

1. Open this repository in GitHub Codespaces using the `ubuntu-24.04-antigravity-desktop` branch.
2. Wait for the dev container image to build and the startup script to finish.
3. Open the **Ports** tab in Codespaces.
4. Open forwarded port **8080**. It is configured as private.
5. Enter the VNC password when noVNC asks for it.

Read the VNC password from the Codespace terminal:

```bash
cat /workspaces/.cloud-home/.vnc-password
```

After the desktop appears, open **Antigravity IDE** from the XFCE Applications menu, or run:

```bash
antigravity-ide
```

Complete Google sign-in inside the desktop. If the IDE asks for a browser, use Firefox from the Applications menu.

## Rebuild

After changing files under `.devcontainer/`, run **Codespaces: Rebuild Container** from the VS Code web Command Palette.

## Important limitations

- GitHub Codespaces is a development environment, not an always-on cloud server. It can stop after inactivity and has monthly included usage limits. It is not a free, permanent 24/7 workstation.
- The workspace repository and the sibling `/workspaces/.cloud-home` volume are intended to preserve project data and IDE settings across container rebuilds. Keep important source changes committed and pushed to GitHub.
- Port 8080 must remain **Private**. Do not expose VNC port 5901 publicly.
- The standalone IDE download is pinned to the official Linux x64 release archive. Update the version and archive URL together when upgrading.
