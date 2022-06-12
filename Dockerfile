ARG TAG=apache
FROM php:$TAG

LABEL maintainer="Dazzit! Corp. <https://github.com/dazzitcorp/>"

#
# Configure Apache
#

RUN set -eux \
    ; \
# Apache: ServerName
    echo "ServerName localhost" | tee /etc/apache2/conf-available/server-name.conf \
    ; \
    a2enconf \
        server-name \
    ; \
# Apache: expires
    a2enmod \
        expires \
    ; \
# Apache: rewrite
    a2enmod \
        rewrite

#
# Configure PHP
#

COPY --from=composer/composer /usr/bin/composer /usr/bin/composer

RUN set -eux \
    ; \
# PHP: php.ini
    cp "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini" \
    ; \
# PHP: APT Start
    apt-get update \
    ; \
    apt-get install --no-install-recommends -y \
        unzip \
        zip \
    ; \
# PHP: bcmath
    docker-php-ext-install \
        bcmath \
    ; \
# PHP: ctype
    docker-php-ext-install \
        ctype \
    ; \
# PHP: exif
    docker-php-ext-install \
        exif \
    ; \
# PHP: gd
    apt-get install --no-install-recommends -y \
        libfreetype6-dev \
        libjpeg-dev \
        libpng-dev \
        libwebp-dev \
    ; \
    docker-php-ext-configure \
        gd \
            --with-freetype \
            --with-jpeg \
            --with-webp \
    ; \
    docker-php-ext-install \
        gd \
    ; \
# PHP: intl
    apt-get install --no-install-recommends -y \
        libicu-dev \
    ; \
    docker-php-ext-install \
        intl \
    ; \
# PHP: zip
    apt-get install --no-install-recommends -y \
        libzip-dev \
    ; \
    docker-php-ext-install \
        zip \
    ; \
# PHP: APT Finsih
    rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

EXPOSE 80

CMD ["apache2-foreground"]