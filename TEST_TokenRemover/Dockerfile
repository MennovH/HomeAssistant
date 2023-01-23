ARG BUILD_FROM
FROM $BUILD_FROM

WORKDIR /

RUN \
  apk add --no-cache \
    python3

ADD rootfs/run.py  /

COPY /rootfs /app
RUN chmod a+x /app/run.sh /app/finish
ENTRYPOINT ["/app/run.sh"]
