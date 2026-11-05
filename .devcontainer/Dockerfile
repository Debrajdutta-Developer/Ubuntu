FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG ANTIGRAVITY_IDE_VERSION=2.6.0
ARG ANTIGRAVITY_IDE_URL="https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/2.6.0-5526304964083712/linux-x64/Antigravity%20IDE.tar.gz"

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=Etc/UTC \
    HOME=/workspaces/.cloud-home \
    DISPLAY=:1 \
    XDG_SESSION_TYPE=x11 \
    XDG_CURRENT_DESKTOP=XFCE

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Ubuntu 24.04 desktop, browser, VNC gateway, Antigravity runtime dependencies,
# and common development tools. Keep the image focused instead of installing
# the full Kali tool collection.
RUN apt-get update && apt-get install -y --no-install-recommends \
      xfce4 xfce4-goodies dbus-x11 dbus-user-session \
      tigervnc-standalone-server tigervnc-tools novnc websockify \
      curl wget ca-certificates gnupg \
      git git-lfs openssh-client \
      python3 python3-pip python3-venv python3-dev \
      nodejs npm build-essential make gcc g++ \
      xauth x11-xserver-utils xterm \
      procps iproute2 net-tools lsof \
      openssl sudo locales unzip zip jq \
      fonts-liberation fonts-dejavu-core \
      libasound2t64 libatk-bridge2.0-0t64 libatk1.0-0t64 \
      libatspi2.0-0t64 libc6 libcairo2 libcups2t64 libdbus-1-3 \
      libdrm2 libgbm1 libglib2.0-0t64 libgtk-3-0t64 \
      libnss3 libsecret-1-0 libx11-6 libxcb1 libxcomposite1 \
      libxdamage1 libxext6 libxfixes3 libxkbcommon0 libxrandr2 \
      libxshmfence1 libxss1 libxtst6 xdg-utils gnome-keyring \
    && locale-gen en_US.UTF-8 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create an unprivileged desktop user. Keeping HOME under /workspaces means
# Antigravity settings and authentication state survive container rebuilds.
RUN useradd --create-home --uid 1000 --shell /bin/bash codespace \
    && mkdir -p /workspaces/Ubuntu /workspaces/.cloud-home /opt/antigravity-ide \
    && chown -R codespace:codespace /workspaces

# Install the official standalone Antigravity IDE Linux x64 archive.
# The upstream download is version-pinned so rebuilds are reproducible.
RUN curl -fL --retry 4 --retry-delay 2 "$ANTIGRAVITY_IDE_URL" -o /tmp/antigravity-ide.tar.gz \
    && tar -xzf /tmp/antigravity-ide.tar.gz -C /opt/antigravity-ide \
    && rm /tmp/antigravity-ide.tar.gz \
    && IDE_BIN="$(find /opt/antigravity-ide -type f \( -name 'antigravity' -o -name 'Antigravity' \) -perm /111 | head -n 1)" \
    && test -n "$IDE_BIN" \
    && printf '#!/bin/sh\nexec "%s" "$@"\n' "$IDE_BIN" > /usr/local/bin/antigravity-ide \
    && chmod 0755 /usr/local/bin/antigravity-ide \
    && cat > /usr/share/applications/antigravity-ide.desktop <<'EOF'
[Desktop Entry]
Name=Antigravity IDE
Comment=Google Antigravity standalone desktop IDE
Exec=/usr/local/bin/antigravity-ide %U
Terminal=false
Type=Application
Categories=Development;IDE;
StartupNotify=true
EOF

# Install Firefox directly from Mozilla's official Linux archive. Ubuntu's
# default Firefox package is a Snap transition package, which is unsuitable
# for this container-based Codespace.
RUN mkdir -p /opt/firefox \
    && curl -fL --retry 4 "https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=en-US" -o /tmp/firefox.tar.xz \
    && tar -xJf /tmp/firefox.tar.xz -C /opt \
    && rm /tmp/firefox.tar.xz \
    && ln -sf /opt/firefox/firefox /usr/local/bin/firefox \
    && cat > /usr/share/applications/firefox.desktop <<'EOF'
[Desktop Entry]
Name=Firefox
Exec=/usr/local/bin/firefox %u
Terminal=false
Type=Application
Categories=Network;WebBrowser;
EOF

COPY .devcontainer/startup.sh /usr/local/bin/ubuntu-codespaces-startup
RUN chmod 0755 /usr/local/bin/ubuntu-codespaces-startup \
    && mkdir -p /var/log/ubuntu-desktop \
    && chown -R codespace:codespace /var/log/ubuntu-desktop /workspaces

USER codespace
WORKDIR /workspaces/Ubuntu
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/ubuntu-codespaces-startup"]
