ARG BUILD_FROM
FROM $BUILD_FROM
WORKDIR /
     
COPY /rootfs/run.sh /app/cfrun.sh
RUN chmod a+x /app/cfrun.sh
ENTRYPOINT ["/app/cfrun.sh"]
