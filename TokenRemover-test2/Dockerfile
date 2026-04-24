ARG BUILD_FROM=ghcr.io/home-assistant/base:3.19
FROM $BUILD_FROM

WORKDIR /

RUN \
  apk add --no-cache \
    python3 \
    tzdata

ADD rootfs/run.py  /

COPY /rootfs /app
RUN chmod a+x /app/run.sh
ENTRYPOINT ["/app/run.sh"]
