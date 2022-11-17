ARG BUILD_FROM
FROM $BUILD_FROM


#Add nginx and create the run folder for nginx.
RUN apk add py3-pip -f \
  && apk add openssl -f \
  && pip3 install homeassistant-cli \
  && apk --no-cache add \
    nginx \
  \
  && mkdir -p /run/nginx \
  && ln -s /usr/bin/ha /usr/lib/ha

#Copy our conf into the nginx http.d folder.
COPY ingress.conf /etc/nginx/http.d/

#Launch nginx with debug options.
CMD [ "nginx","-g","daemon off;error_log /dev/stdout debug;" ]

WORKDIR /

COPY /rootfs/run.sh /app/run.sh
RUN chmod a+x /app/run.sh
ENTRYPOINT ["/app/run.sh"]
