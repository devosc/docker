ARG RELEASE_VERSION=apache

FROM php:$RELEASE_VERSION

# Time Zone
ARG TIME_ZONE=UTC
RUN set -ex && rm /etc/localtime && \
    ln -s /usr/share/zoneinfo/${TIME_ZONE} /etc/localtime

# PHP settings
RUN set -ex && cp $PHP_INI_DIR/php.ini-development $PHP_INI_DIR/php.ini && \
    echo "date.timezone=${TIME_ZONE}" | tee $PHP_INI_DIR/conf.d/timezone.ini

# App user
ARG USER_ID=1000
ARG GROUP_ID=1000
RUN if [ $(getent group $GROUP_ID | cut -d: -f1) ]; then groupdel $(getent group $GROUP_ID | cut -d: -f1) ; fi && \
    groupadd -r app -g $GROUP_ID && \
    useradd -u $USER_ID -r -l -g app -m -s /sbin/nologin -c "App user" app

# Dependencies
ARG BUILD_DEPS
ARG PHP_EXT_CONFIGURE
ARG PHP_EXT_INSTALL
RUN set -ex && apt-get update \
    && apt-get install -y --no-install-recommends \
        libicu-dev \
        libjpeg-dev \
        libpng-dev \
        libpq-dev \
        libzip-dev \
        curl \
        git \
        gnupg \
        less \
        locales-all \
        nano \
        openssh-client \
        unzip \
        zip \
        ${BUILD_DEPS} \
    && docker-php-ext-configure gd --with-jpeg \
    && echo "$PHP_EXT_CONFIGURE" | tr ";" "\n" | while read ext ; do \
            if [ -n "${ext}" ]; then \
                docker-php-ext-configure ${ext}; \
            fi \
        done \
    && docker-php-ext-install -j$(nproc) bcmath gd intl mysqli opcache pcntl pdo pdo_mysql pdo_pgsql zip ${PHP_EXT_INSTALL} \
    && rm -rf /var/lib/apt/lists/*

# Locale
ARG LOCALE
ENV LANG ${LOCALE}

# Opcache default settings
ARG OPCACHE_DEFAULTS=true
RUN set -ex && if [ $OPCACHE_DEFAULTS = "true" ]; then \
{ \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=2'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.enable_cli=1'; \
} > $PHP_INI_DIR/conf.d/opcache.ini; fi

# Xdebug
ARG XDEBUG=false
RUN if [ $XDEBUG = "true" ]; then pecl install xdebug && docker-php-ext-enable xdebug; fi

# Composer
ARG COMPOSER=true
RUN if [ $COMPOSER = "true" ]; then \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer; fi

# npm
ARG NODE_JS=false
ARG NODE_VERSION="setup_13.x"
RUN if [ $NODE_JS = "true" ]; then \
    curl -sL https://deb.nodesource.com/$NODE_VERSION | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*; fi

# Mail
ARG MAIL=true
ARG MAIL_HOST="mailhog:1025"
ARG MAILHOG_VERSION="v0.2.0"
RUN if [ $MAIL = "true" ]; then \
    curl -sL https://github.com/mailhog/mhsendmail/releases/download/$MAILHOG_VERSION/mhsendmail_linux_amd64 \
    -o /usr/local/bin/mhsendmail  \
    && chmod +x /usr/local/bin/mhsendmail \
    && echo "sendmail_path = \"/usr/local/bin/mhsendmail --smtp-addr=$MAIL_HOST\"" | tee $PHP_INI_DIR/conf.d/mail.ini; fi

# WP-CLI
ARG WP_CLI=false
RUN if [ $WP_CLI = "true" ]; then \
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp; fi

# PHPUnit
ARG PHPUNIT=true
ARG PHPUNIT_VERSION="9"
RUN if [ $PHPUNIT = "true" ]; then \
    curl -O https://phar.phpunit.de/phpunit-${PHPUNIT_VERSION}.phar \
    && chmod +x phpunit-${PHPUNIT_VERSION}.phar \
    && mv phpunit-${PHPUNIT_VERSION}.phar /usr/local/bin/phpunit; fi

# Apache
ARG WWW_USER=app
ARG WWW_GROUP=app
ENV APACHE_RUN_USER $WWW_USER
ENV APACHE_RUN_GROUP $WWW_GROUP
ARG DOCUMENT_ROOT=/var/www/public
ENV APACHE_DOCUMENT_ROOT $DOCUMENT_ROOT
ARG APACHE_LOG_LEVEL=info
ENV APACHE_LOG_LEVEL $APACHE_LOG_LEVEL
ARG REDIRECT_TRAILING_SLASH=false
ENV REDIRECT_TRAILING_SLASH=$REDIRECT_TRAILING_SLASH
WORKDIR /var/www
COPY vhost.conf ${APACHE_CONFDIR}/sites-available/000-default.conf
RUN set -ex && echo "ServerName localhost" > ${APACHE_CONFDIR}/conf-available/server-name.conf \
    && a2enconf server-name \
    && a2enmod rewrite expires
