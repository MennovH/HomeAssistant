ARG BUILD_FROM=ghcr.io/home-assistant/base:latest
FROM $BUILD_FROM

WORKDIR /app

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

COPY rootfs /app
RUN chmod a+x /app/run.sh

ENTRYPOINT ["/app/run.sh"]