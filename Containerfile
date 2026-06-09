ARG NEXTCLOUD_VERSION
FROM public.ecr.aws/docker/library/nextcloud:${NEXTCLOUD_VERSION}-apache

RUN set -ex; \
    apt-get update; \
    apt-get install -y --no-install-recommends ffmpeg ghostscript procps smbclient; \
    apt-get dist-clean

RUN set -ex; \
    savedAptMark="$(apt-mark showmanual)"; \
    \
    apt-get update; \
    apt-get install -y --no-install-recommends libsmbclient-dev; \
    pecl install smbclient; \
    docker-php-ext-enable smbclient; \
    rm -r /tmp/pear; \
    \
    # reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
    apt-mark auto '.*' > /dev/null; \
    apt-mark manual $savedAptMark; \
    ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
    | awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); print so }' \
    | sort -u \
    | xargs -rt dpkg-query --search \
    | awk 'sub(":$", "", $1) { print $1 }' \
    | sort -u \
    | xargs -rt apt-mark manual; \
    \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    apt-get dist-clean

COPY --chown=65534:65534 dist/ /usr/src/nextcloud/apps/
