ARG BUILD_FROM
FROM $BUILD_FROM

WORKDIR /

RUN \
  apk add --no-cache \
    python3

ADD rootfs/run.py  /

COPY /rootfs/run.sh /app/run.sh
RUN chmod a+x /app/run.sh
ENTRYPOINT ["/app/run.sh"]
