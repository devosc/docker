ARG CLI_RELEASE_VERSION=cli

FROM php:$CLI_RELEASE_VERSION

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
        ssmtp \
        unzip \
        zip \
        ${BUILD_DEPS} \
    && docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
    && docker-php-ext-configure zip --with-libzip \
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

# Mail
ARG MAIL=true
ARG MAIL_HOST="mailhog:1025"
RUN if [ $MAIL = "true" ]; then \
    echo 'sendmail_path = "/usr/sbin/ssmtp -t"' | tee $PHP_INI_DIR/conf.d/mail.ini \
    && sed -i "s/mailhub=mail/mailhub=$MAIL_HOST/g" /etc/ssmtp/ssmtp.conf \
    && sed -i "s/#FromLineOverride=YES/FromLineOverride=YES/g" /etc/ssmtp/ssmtp.conf; fi

# PHPUnit
ARG PHPUNIT=true
ARG PHPUNIT_VERSION="7.5.1"
RUN if [ $PHPUNIT = "true" ]; then \
    curl -O https://phar.phpunit.de/phpunit-${PHPUNIT_VERSION}.phar \
    && chmod +x phpunit-${PHPUNIT_VERSION}.phar \
    && mv phpunit-${PHPUNIT_VERSION}.phar /usr/local/bin/phpunit; fi
