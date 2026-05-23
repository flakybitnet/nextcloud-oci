FROM public.ecr.aws/docker/library/php:8.3-apache-trixie

RUN set -ex; \
    apt-get update; \
    apt-get install -y --no-install-recommends libldap-common libmagickcore-7.q16-10-extra gettext-base ffmpeg nano; \
    apt-get dist-clean

ENV PHP_MEMORY_LIMIT 512M
ENV PHP_UPLOAD_LIMIT 512M
ENV PHP_OPCACHE_MEMORY_CONSUMPTION 128
RUN set -ex; \
    savedAptMark="$(apt-mark showmanual)"; \
    \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        libcurl4-openssl-dev \
        libevent-dev \
        libfreetype6-dev \
        libgmp-dev \
        libicu-dev \
        libjpeg-dev \
        libldap2-dev \
        liblz4-dev \
        libmagickwand-dev \
        libmemcached-dev \
        libpng-dev \
        libpq-dev \
        libwebp-dev \
        libxml2-dev \
        libzip-dev \
    ; \
    \
    debMultiarch="$(dpkg-architecture --query DEB_BUILD_MULTIARCH)"; \
    docker-php-ext-configure ftp --with-openssl-dir=/usr; \
    docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp; \
    docker-php-ext-configure ldap --with-libdir="lib/$debMultiarch"; \
    docker-php-ext-install -j "$(nproc)" \
        bcmath \
        exif \
        ftp \
        gd \
        gmp \
        intl \
        ldap \
        pcntl \
        pdo_mysql \
        pdo_pgsql \
        sysvsem \
        zip \
    ; \
    \
    pecl install APCu-5.1.28; \
    pecl install igbinary-3.2.16; \
    pecl install imagick-3.8.1; \
    pecl install --configureoptions 'enable-memcached-igbinary="yes"' memcached-3.4.0; \
    pecl install --configureoptions 'enable-redis-igbinary="yes" enable-redis-zstd="yes" enable-redis-lz4="yes"' redis-6.3.0; \
    \
    docker-php-ext-enable \
        apcu \
        igbinary \
        imagick \
        memcached \
        redis \
    ; \
    rm -r /tmp/pear; \
    \
    # reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
    apt-mark auto '.*' > /dev/null; \
    apt-mark manual $savedAptMark; \
    ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
        | awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); print so }' \
        | sort -u \
        | xargs -rt dpkg-query --search \
        # https://manpages.debian.org/trixie/dpkg/dpkg-query.1.en.html#S (we ignore diversions and it'll be really unusual for more than one package to provide any given .so file)
        | awk 'sub(":$", "", $1) { print $1 }' \
        | sort -u \
        | xargs -rt apt-mark manual; \
    \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    apt-get dist-clean

COPY php/ /usr/src/nextcloud/config/php/
RUN set -ex; \
    cat /usr/src/nextcloud/config/php/docker-php-ext-apcu.ini >> "${PHP_INI_DIR}/conf.d/docker-php-ext-apcu.ini"; \
    cat /usr/src/nextcloud/config/php/docker-php-ext-igbinary.ini >> "${PHP_INI_DIR}/conf.d/docker-php-ext-igbinary.ini"; \
    cat /usr/src/nextcloud/config/php/opcache-recommended.ini | envsubst > "${PHP_INI_DIR}/conf.d/opcache-recommended.ini"; \
    cat /usr/src/nextcloud/config/php/nextcloud.ini | envsubst > "${PHP_INI_DIR}/conf.d/nextcloud.ini";

ENV APACHE_BODY_LIMIT 1073741824
COPY apache/ /usr/src/nextcloud/config/apache/
RUN set -ex; \
    a2enmod headers rewrite remoteip ; \
    cp /usr/src/nextcloud/config/apache/remoteip.conf /etc/apache2/conf-available/remoteip.conf; \
    cat /usr/src/nextcloud/config/apache/apache-limits.conf | envsubst > /etc/apache2/conf-available/apache-limits.conf; \
    a2enconf remoteip apache-limits

ARG NEXTCLOUD_VERSION
ENV NEXTCLOUD_VERSION=$NEXTCLOUD_VERSION

COPY --chown=www-data:www-data dist/nextcloud/ /var/www/html/
COPY --chown=www-data:www-data config/ /var/www/html/config/
COPY --chmod=755 scripts/ /bin/nc/

ENTRYPOINT ["/bin/nc/start.sh"]
