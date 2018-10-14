ARG RELEASE_VERSION=apache

FROM php:$RELEASE_VERSION

# Development settings
RUN cp /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini

# App user
ARG USER_ID=1000
ARG GROUP_ID=1000
RUN if [ $(getent group $GROUP_ID | cut -d: -f1) ]; then groupdel $(getent group $GROUP_ID | cut -d: -f1) ; fi && \
    groupadd -r app -g $GROUP_ID && \
    useradd -u $USER_ID -r -l -g app -m -s /sbin/nologin -c "App user" app

# Dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        curl \
        zip \
        unzip \
        nano \
        gnupg \
        libicu-dev \
        libzip-dev \
        libjpeg-dev \
        libpng-dev \
    && docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
    && docker-php-ext-install pdo pdo_mysql mysqli intl zip gd \
    && rm -rf /var/lib/apt/lists/*

# Opcache
RUN docker-php-ext-install opcache && { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=2'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.enable_cli=1'; \
} > /usr/local/etc/php/conf.d/opcache.ini

# Xdebug
ARG XDEBUG=false
RUN if [ $XDEBUG = "true" ]; then pecl install xdebug && docker-php-ext-enable xdebug; fi

# Composer
ARG COMPOSER=true
RUN if [ $COMPOSER = "true" ]; then \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer; fi

# npm
ARG NODE_JS=false
RUN if [ $NODE_JS = "true" ]; then \
    curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*; fi

# Apache
ARG WWW_USER=app
ARG WWW_GROUP=app
ENV APACHE_RUN_USER $WWW_USER
ENV APACHE_RUN_GROUP $WWW_GROUP
ARG DOCUMENT_ROOT=/var/www/public
ENV APACHE_DOCUMENT_ROOT $DOCUMENT_ROOT
WORKDIR /var/www
RUN a2enmod rewrite expires
COPY vhost.conf /etc/apache2/sites-available/000-default.conf
