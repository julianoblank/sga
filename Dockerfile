#Build stage, useful for a better use of cache ;)
FROM php:7.1-apache

ENV NOVOSGA_VER=v2.0.3 \
    NOVOSGA_MD5=11eeee4de02f261830308eb3f1d802b8
    
ENV NOVOSGA_FILE=novosga.tar.gz \
    NOVOSGA_DIR=/var/www/html \
    APP_ENV=prod
    
RUN set -xe \
    && mkdir -p $NOVOSGA_DIR && cd $NOVOSGA_DIR \
    && docker-php-ext-install pcntl 
  # && composer install --no-dev -o
   
RUN set -xe \
    && apt-get update \
    && apt-get install -y \
        cron \
        libicu-dev \
        libxml2-dev \
        zlib1g-dev \
        supervisor \
    && docker-php-ext-install \
        intl \
        pcntl \
        pdo \
        pdo_mysql \
        xml \
        zip \
    && apt-get remove -y --purge \
        postgresql-server-dev-all \
        libicu-dev \
        libxml2-dev \
        zlib1g-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && a2enmod rewrite env \
    && echo 'session.save_path = "/tmp"' > /usr/local/etc/php/conf.d/sessionsavepath.ini \
    && echo 'date.timezone = ${TZ}' > /usr/local/etc/php/conf.d/datetimezone.ini

#VOLUME ../../../Totem-SGA /var/www/html/
#COPY C:\Users\julianae\workspace\Totem-SGA\*.* /var/www/html
#COPY ../../../Totem-SGA /var/www/html/

RUN set -xe \
    && chown -R www-data:www-data . \
    && sed -i 's|/var/www/html|/var/www/html/public|g' /etc/apache2/sites-available/000-default.conf

#Set the default parameters
ENV APP_ENV=prod \
    LANGUAGE=pt_BR \
    NOVOSGA_ADMIN_USERNAME="admin" \
    NOVOSGA_ADMIN_PASSWORD="123456" \
    NOVOSGA_ADMIN_FIRSTNAME="Administrator" \
    NOVOSGA_ADMIN_LASTNAME="Global" \
    NOVOSGA_UNITY_NAME="My Unity" \
    NOVOSGA_UNITY_CODE="U01" \
    NOVOSGA_NOPRIORITY_NAME="Normal" \
    NOVOSGA_NOPRIORITY_DESCRIPTION="Normal service" \
    NOVOSGA_PRIORITY_NAME="Priority" \
    NOVOSGA_PRIORITY_DESCRIPTION="Priority service" \
    NOVOSGA_PLACE_NAME="Box"

#COPY start.sh /usr/local/bin
COPY apache2/htaccess public/.htaccess
COPY supervisor/apache2.conf /etc/supervisor/conf.d/apache2.conf
COPY supervisor/cron.conf /etc/supervisor/conf.d/cron.conf
COPY supervisor/websocket.conf /etc/supervisor/conf.d/websocket.conf

ADD crontab/cron /etc/cron.d/app
RUN chmod 644 /etc/cron.d/app \
    && curl -fSL https://getcomposer.org/composer.phar -o composer.phar \
    && chmod +X composer.phar \
    && mv composer.phar /usr/local/bin/composer \
    && chmod 775 /usr/local/bin/composer \
    && curl -fSL https://getcomposer.org/composer.phar -o composer.phar

