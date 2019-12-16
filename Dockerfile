FROM extremeshok/baseimage-alpine:latest AS BUILD

LABEL mantainer="Adrian Kriel <admin@extremeshok.com>" vendor="eXtremeSHOK.com"

RUN \
  echo "**** install nginx ****" \
  && apk-install nginx

RUN \
  echo "**** install bash runtime packages ****" \
  && apk-install \
    bash \
    coreutils \
    curl \
    inotify-tools \
    openssl \
    tzdata

# add local files
COPY ./rootfs/ /

RUN \
  echo "**** Symlink the logs to stdout and stderr ****" \
  && ln -sf /dev/stdout /var/log/nginx/access.log \
  && ln -sf /dev/stderr /var/log/nginx/error.log

RUN \
  echo "**** configure ****" \
  && mkdir -p /certs \
  && mkdir -p /tmp/nginx_cache \
  && mkdir -p /etc/nginx/sites.d \
  && chown -R nginx:nginx /var/www \
  && chmod 777 /xshok_gen_nginx_proxy_conf.sh \
  && chmod 777 /xshok-monitor-certs.sh

EXPOSE 443/tcp

WORKDIR /tmp

ENTRYPOINT ["/init"]
