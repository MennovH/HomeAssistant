ARG BUILD_FROM=ghcr.io/home-assistant/base:latest
FROM $BUILD_FROM

WORKDIR /

RUN apk add --no-cache \
    python3 \
    py3-pip \
    tzdata \
  && pip3 install --no-cache-dir websockets

ADD rootfs/run.py  /
ADD rootfs/revoke.py  /

COPY /rootfs /app
RUN chmod a+x /app/run.sh
ENTRYPOINT ["/app/run.sh"]
