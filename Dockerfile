ARG RELEASE_VERSION=apache

FROM php:$RELEASE_VERSION

# App user
ARG USER_ID=1000
ARG GROUP_ID=1000
ARG XDEBUG=false

RUN if [ $(getent group $GROUP_ID | cut -d: -f1) ]; then groupdel $(getent group $GROUP_ID | cut -d: -f1) ; fi && \
    groupadd -r app -g $GROUP_ID && \
    useradd -u $USER_ID -r -l -g app -m -s /sbin/nologin -c "App user" app && \
    mkdir -p /var/www && chown -R app:app /var/www && rm -rf /var/www/html

# PHP
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    curl \
    nginx \
    zip \
    unzip \
    nano \
    gnupg \
    build-essential \
    libssl-dev \
  && rm -rf /var/lib/apt/lists/*

# Development settings
RUN cp  /usr/local/etc/php/php.ini-development  /usr/local/etc/php/php.ini

# Opcache
RUN docker-php-ext-install opcache

# Xdebug
RUN if [ $XDEBUG = "true" ]; then pecl install xdebug && \
    docker-php-ext-enable xdebug; fi

# Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# NPM
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get install -y --no-install-recommends \
    nodejs \
  && rm -rf /var/lib/apt/lists/*

# Apache
WORKDIR /var/www
RUN a2enmod rewrite
COPY vhost.conf /etc/apache2/sites-available/000-default.conf