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
    curl \
    zip \
    unzip \
    nano \
    gnupg \
  && rm -rf /var/lib/apt/lists/*

# Opcache
RUN docker-php-ext-install opcache

# Xdebug
ARG XDEBUG=false
RUN if [ $XDEBUG = "true" ]; then pecl install xdebug && docker-php-ext-enable xdebug; fi

# Composer
ARG COMPOSER=true
RUN if [ $COMPOSER = "true" ]; then \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer; fi

# NPM
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get install -y --no-install-recommends \
    nodejs \
  && rm -rf /var/lib/apt/lists/*

# Apache
ARG WWW_USER=app
ARG WWW_GROUP=app
ENV APACHE_RUN_USER $WWW_USER
ENV APACHE_RUN_GROUP $WWW_GROUP
ARG DOCUMENT_ROOT=/var/www/public
ENV APACHE2_DEFAULT_DOCUMENT_ROOT $DOCUMENT_ROOT
WORKDIR /var/www
RUN a2enmod rewrite
COPY vhost.conf /etc/apache2/sites-available/000-default.conf
