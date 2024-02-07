

# # Execute during the build of the image
# ARG TEMPIO_VERSION BUILD_ARCH
# RUN \
#     curl -sSLf -o /usr/bin/tempio \
#     "https://github.com/home-assistant/tempio/releases/download/${TEMPIO_VERSION}/tempio_${BUILD_ARCH}"

# # Copy root filesystem
# COPY rootfs /




# ARG BUILD_FROM
# FROM $BUILD_FROM

# #Add nginx and create the run folder for nginx.
# RUN \
#   apk add --no-cache \
#     python3 \
#   && apk --no-cache add \
#     nginx \
#   \
#   && mkdir -p /run/nginx

# #Copy our conf into the nginx http.d folder.
# COPY ingress.conf /etc/nginx/http.d/

# #Launch nginx with debug options.
# CMD [ "nginx","-g","daemon off;error_log /dev/stdout debug;" ]

ARG BUILD_FROM=ghcr.io/hassio-addons/base:15.0.6
# hadolint ignore=DL3006
FROM ${BUILD_FROM}

ARG BUILD_ARCH=amd64

RUN \
    apk add --no-cache \
        nginx=1.24.0-r15 \
        yq=4.35.2-r1 \
    \
    && if [[ "${BUILD_ARCH}" = "aarch64" ]]; then ARCH="arm64"; fi \
    && if [[ "${BUILD_ARCH}" = "amd64" ]]; then ARCH="amd64"; fi \
    && if [[ "${BUILD_ARCH}" = "armv7" ]]; then ARCH="armv7"; fi \
    \
    && curl -L -s \
        "https://github.com/AdguardTeam/AdGuardHome/releases/download/${ADGUARD_HOME_VERSION}/AdGuardHome_linux_${ARCH}.tar.gz" \
        | tar zxvf - -C /opt/ \
    \
    && chmod a+x /opt/AdGuardHome/AdGuardHome \
    \
    && rm -fr \
        /etc/nginx \
        /tmp/*

 # Copy root filesystem
COPY rootfs /
