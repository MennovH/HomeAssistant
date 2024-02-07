

# # Execute during the build of the image
# ARG TEMPIO_VERSION BUILD_ARCH
# RUN \
#     curl -sSLf -o /usr/bin/tempio \
#     "https://github.com/home-assistant/tempio/releases/download/${TEMPIO_VERSION}/tempio_${BUILD_ARCH}"

# # Copy root filesystem
# COPY rootfs /




ARG BUILD_FROM
FROM $BUILD_FROM

#Add nginx and create the run folder for nginx.
RUN \
  apk add --no-cache \
    python3 \
  && apk --no-cache add \
    nginx \
  \
  && mkdir -p /run/nginx

#Copy our conf into the nginx http.d folder.
COPY ingress.conf /etc/nginx/http.d/

#Launch nginx with debug options.
CMD [ "nginx","-g","daemon off;error_log /dev/stdout debug;" ]

