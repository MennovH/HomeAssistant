ARG BUILD_FROM
FROM $BUILD_FROM

WORKDIR /

RUN \
  apk add --no-cache \
    python3 \
  && apk add --no-cache \
    py3-pip=22.3.1-r1 \
    \
    && pip install requests

ADD rootfs/run.py  /

COPY /rootfs/run.sh /app/run.sh
RUN chmod a+x /app/run.sh
ENTRYPOINT ["/app/run.sh"]
