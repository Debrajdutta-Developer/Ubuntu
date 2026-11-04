FROM kalilinux/kali-rolling:latest

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=Etc/UTC

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
      kali-linux-headless \
      xfce4 xfce4-goodies dbus-x11 \
      novnc websockify \
      firefox-esr chromium \
      postgresql postgresql-contrib \
      git curl wget ca-certificates gnupg \
      python3 python3-pip python3-venv \
      nodejs npm \
      xauth x11-xserver-utils xterm \
      supervisor procps iproute2 net-tools \
      openssl sudo locales \
    && if apt-cache show tightvncserver >/dev/null 2>&1; then \
         apt-get install -y --no-install-recommends tightvncserver; \
       else \
         apt-get install -y --no-install-recommends tigervnc-standalone-server; \
       fi \
    && locale-gen en_US.UTF-8 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Kali rolling may ship TigerVNC instead of the retired TightVNC package.
# This compatibility command preserves the requested tightvncserver interface.
RUN if ! command -v tightvncserver >/dev/null 2>&1; then \
      VNC_BIN="$(command -v tigervncserver || command -v vncserver)"; \
      test -n "$VNC_BIN"; \
      printf '#!/bin/sh\nexec "%s" "$@"\n' "$VNC_BIN" > /usr/local/bin/tightvncserver; \
      chmod 0755 /usr/local/bin/tightvncserver; \
    fi \
    && install -d -m 0755 /workspace /root/.vnc /var/log/kali-desktop

# Ensure PostgreSQL has a default cluster. Debian/Kali package installation
# normally creates one, but this also covers images where post-install did not.
RUN if ! pg_lsclusters --no-header | grep -q .; then \
      pg_createcluster --start 16 main; \
    fi \
    && sed -ri "s/^#?listen_addresses\s*=.*/listen_addresses = 'localhost'/" /etc/postgresql/*/main/postgresql.conf

COPY .devcontainer/startup.sh /usr/local/bin/kali-codespaces-startup
RUN chmod 0755 /usr/local/bin/kali-codespaces-startup

EXPOSE 8080

WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/kali-codespaces-startup"]
