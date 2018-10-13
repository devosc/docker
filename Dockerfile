ARG RELEASE_VERSION=apache

FROM php:$RELEASE_VERSION

# Development settings
RUN cp /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini

# App user
ARG USER_ID=1000
ARG GROUP_ID=1000
ARG XDEBUG=false

RUN if [ $(getent group $GROUP_ID | cut -d: -f1) ]; then groupdel $(getent group $GROUP_ID | cut -d: -f1) ; fi && \
    groupadd -r app -g $GROUP_ID && \
    useradd -u $USER_ID -r -l -g app -m -s /sbin/nologin -c "App user" app && \
    mkdir -p /var/www && chown -R app:app /var/www && rm -rf /var/www/html

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
RUN if [ $XDEBUG = "true" ]; then pecl install xdebug && \
    docker-php-ext-enable xdebug; fi

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
WORKDIR /var/www
RUN a2enmod rewrite
COPY vhost.conf /etc/apache2/sites-available/000-default.conf
