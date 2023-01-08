ARG BUILD_FROM
FROM $BUILD_FROM

WORKDIR /

RUN \
  apk add --no-cache \
    python3 \
  && apk add --no-cache \
    at
     
COPY /rootfs/run.sh /app/run.sh
COPY /rootfs/run.py /app/run.py
RUN chmod a+x /app/run.sh
ENTRYPOINT ["/app/run.sh"]
