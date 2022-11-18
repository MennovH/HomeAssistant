ARG BUILD_FROM
FROM $BUILD_FROM

WORKDIR /
     
COPY /rootfs/run.sh /app/run.sh
RUN chmod a+x /app/run.sh
ENTRYPOINT ["/app/run.sh"]
