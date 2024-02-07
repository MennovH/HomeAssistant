ARG BUILD_FROM
FROM $BUILD_FROM

# Install requirements for add-on
RUN \
  apk add --no-cache \
    python3

# Python 3 HTTP Server serves the current working dir
# So let's set it to our add-on persistent data directory.
WORKDIR /data/html.index

# #Copy our conf into the nginx http.d folder.
# COPY ingress.conf /etc/nginx/http.d/

# #Launch nginx with debug options.
# CMD [ "nginx","-g","daemon off;error_log /dev/stdout debug;" ]

# Copy data for add-on
COPY /rootfs /
RUN chmod a+x /run.sh
RUN chmod a+x /html.index

# CMD [ "/run.sh" ]

CMD [ "python3 -m http.server 8500 -d /hmtl.index" ]
