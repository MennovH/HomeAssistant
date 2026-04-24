ARG BUILD_FROM=ghcr.io/home-assistant/base:latest
FROM $BUILD_FROM

WORKDIR /

RUN apk add --no-cache \
    python3 \
    py3-pip \
    py3-virtualenv \
    tzdata

# Maak virtualenv
RUN python3 -m venv /opt/venv

# Activeer venv en installeer packages
RUN /opt/venv/bin/pip install --no-cache-dir websockets

# Zorg dat venv standaard gebruikt wordt
ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /app
COPY rootfs /app
RUN chmod a+x /run.sh

ENTRYPOINT ["/run.sh"]