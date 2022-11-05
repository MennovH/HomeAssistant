ARG BUILD_FROM
FROM ${BUILD_FROM}

#Add nginx and create the run folder for nginx.
#RUN \
#  apk --no-cache add \
#    nginx \
#  \
#  && mkdir -p /run/nginx

#Copy our conf into the nginx http.d folder.
#COPY ingress.conf /etc/nginx/http.d/

#Launch nginx with debug options.
#CMD [ "nginx","-g","daemon off;error_log /dev/stdout debug;" ]

WORKDIR /

#COPY rootfs /
COPY rootfs /
RUN chmod a+x /rootfs/run.sh
ENTRYPOINT ["/rootfs/run.sh"]
