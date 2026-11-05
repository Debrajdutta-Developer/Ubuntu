FROM kalilinux/kali-rolling:latest

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=Etc/UTC

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install the Kali headless toolset, lightweight desktop, browser gateway,
# browsers, database, and common development toolchains in one layer.
RUN apt-get update && apt-get install -y --no-install-recommends \
      kali-linux-headless \
      xfce4 xfce4-goodies dbus-x11 dbus-x11 \
      tigervnc-standalone-server tigervnc-tools \
      novnc websockify \
      firefox-esr chromium \
      postgresql postgresql-contrib \
      git git-lfs curl wget ca-certificates gnupg \
      python3 python3-pip python3-venv python3-dev \
      nodejs npm \
      build-essential make gcc g++ \
      xauth x11-xserver-utils xterm \
      procps iproute2 net-tools lsof \
      openssl sudo locales unzip zip jq \
      fonts-liberation \
    && locale-gen en_US.UTF-8 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Kali Rolling may not ship the legacy TightVNC package. TigerVNC provides
# the compatible VNC server; this wrapper keeps the requested command name.
RUN VNC_BIN="$(command -v tigervncserver || command -v vncserver)" \
    && test -n "$VNC_BIN" \
    && printf '#!/bin/sh\nexec "%s" "$@"\n' "$VNC_BIN" > /usr/local/bin/tightvncserver \
    && chmod 0755 /usr/local/bin/tightvncserver \
    && install -d -m 0755 /workspaces/Ubuntu /root/.vnc /var/log/kali-desktop

# Create the PostgreSQL main cluster during image build. The service itself
# starts at container runtime, not while the image is being built.
RUN if ! pg_lsclusters --no-header | awk '$2 == "main" { found=1 } END { exit !found }'; then \
      PG_MAJOR="$(pg_config --version | awk '{print $2}' | cut -d. -f1)" \
      && pg_createcluster "$PG_MAJOR" main; \
    fi \
    && sed -ri "s/^#?listen_addresses\\s*=.*/listen_addresses = 'localhost'/" /etc/postgresql/*/main/postgresql.conf

COPY .devcontainer/startup.sh /usr/local/bin/kali-codespaces-startup
RUN chmod 0755 /usr/local/bin/kali-codespaces-startup

EXPOSE 8080

WORKDIR /workspaces/Ubuntu
ENTRYPOINT ["/usr/local/bin/kali-codespaces-startup"]
