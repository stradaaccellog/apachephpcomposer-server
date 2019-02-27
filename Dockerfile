FROM php:7.0.33-apache AS webservice

LABEL maintainer="valter@accellog.com"

# ferramentas básicas para o funcionamento
RUN apt-get update \
    && apt-get install -y apt-utils \
    && apt-get install -y vim \
    && apt-get install -y net-tools \
    && apt-get install -y wget

# instalando PostgreSQL PDO
RUN apt-get install -y libpq-dev \
    && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-install pdo pdo_pgsql pgsql

# instalando o componente zip do php
RUN apt-get install -y zlib1g-dev \
    && docker-php-ext-install zip

# módulo necessário para redirecionar para HTTPS
RUN a2enmod rewrite \
    && a2enmod socache_shmcb \
    && a2enmod ssl

# instalando composer
# https://hub.docker.com/_/composer/
RUN apt-get update \
    && apt-get install -y git subversion mercurial unzip

RUN echo "memory_limit=-1" > "$PHP_INI_DIR/conf.d/memory-limit.ini"

ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_HOME /tmp
ENV COMPOSER_VERSION 1.8.4

RUN curl --silent --fail --location --retry 3 --output /tmp/installer.php --url https://raw.githubusercontent.com/composer/getcomposer.org/cb19f2aa3aeaa2006c0cd69a7ef011eb31463067/web/installer \
 && php -r " \
    \$signature = '48e3236262b34d30969dca3c37281b3b4bbe3221bda826ac6a9a62d6444cdb0dcd0615698a5cbe587c3f0fe57a54d8f5'; \
    \$hash = hash('sha384', file_get_contents('/tmp/installer.php')); \
    if (!hash_equals(\$signature, \$hash)) { \
        unlink('/tmp/installer.php'); \
        echo 'Integrity check failed, installer is either corrupt or worse.' . PHP_EOL; \
        exit(1); \
    }" \
 && php /tmp/installer.php --no-ansi --install-dir=/usr/bin --filename=composer --version=${COMPOSER_VERSION} \
 && composer --ansi --version --no-interaction \
&& rm -f /tmp/installer.php

# baixando e configurando scripts certbot-auto
RUN  cd /usr/bin \
    && wget https://dl.eff.org/certbot-auto \
    && chmod a+x ./certbot-auto \
    && ./certbot-auto --os-packages-only -n

# componentes para o envio de emails e emissão de recibos
RUN apt-get update -y && apt-get install -y sendmail libpng-dev \
    && docker-php-ext-install mbstring \
    && docker-php-ext-install gd \
    && docker-php-ext-install gettext

RUN apt-get update && \
    apt-get install -y \
        libc-client-dev libkrb5-dev && \
    rm -r /var/lib/apt/lists/*

RUN docker-php-ext-configure imap --with-kerberos --with-imap-ssl && \
    docker-php-ext-install -j$(nproc) imap

VOLUME /var/www/html
WORKDIR /var/www/html
EXPOSE 80 80
EXPOSE 443 443
