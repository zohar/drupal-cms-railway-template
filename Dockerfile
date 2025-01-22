#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

# https://www.drupal.org/docs/system-requirements/php-requirements
FROM php:8.3-apache-bookworm

# install the PHP extensions we need
RUN set -eux; \
    \
    if command -v a2enmod; then \
# https://github.com/drupal/drupal/blob/d91d8d0a6d3ffe5f0b6dde8c2fbe81404843edc5/.htaccess (references both mod_expires and mod_rewrite explicitly)
        a2enmod expires rewrite; \
    fi; \
    \
    savedAptMark="$(apt-mark showmanual)"; \
    \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        libfreetype6-dev \
        libjpeg-dev \
        libpng-dev \
        libpq-dev \
        libwebp-dev \
        libzip-dev \
        default-mysql-client \
    ; \
    \
    docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg=/usr \
        --with-webp \
    ; \
    \
    docker-php-ext-install -j "$(nproc)" \
        gd \
        opcache \
        pdo_mysql \
        pdo_pgsql \
        zip \
    ; \
    \
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
    apt-mark auto '.*' > /dev/null; \
    apt-mark manual $savedAptMark; \
    apt-mark manual default-mysql-client; \
    ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
        | awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); printf "*%s\n", so }' \
        | sort -u \
        | xargs -r dpkg-query -S \
        | cut -d: -f1 \
        | sort -u \
        | xargs -rt apt-mark manual; \
    \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/*

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=4000'; \
        echo 'opcache.revalidate_freq=60'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

# Increase PHP memory imit to avoid "Fatal error: Allowed memory size" errors
RUN echo "memory_limit = 420M" > /usr/local/etc/php/conf.d/custom-memory-limit.ini

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/

# 2025-01-06: https://www.drupal.org/project/drupal/releases/11.1.1
ENV DRUPAL_VERSION 11.1.1

# https://github.com/docker-library/drupal/pull/259
# https://github.com/moby/buildkit/issues/4503
# https://github.com/composer/composer/issues/11839
# https://github.com/composer/composer/issues/11854
# https://github.com/composer/composer/blob/94fe2945456df51e122a492b8d14ac4b54c1d2ce/src/Composer/Console/Application.php#L217-L218
ENV COMPOSER_ALLOW_SUPERUSER 1

WORKDIR /opt/drupal
RUN set -eux; \
    export COMPOSER_HOME="$(mktemp -d)"; \
    composer create-project --no-interaction "drupal/cms" ./; \
# https://github.com/docker-library/drupal/pull/266#issuecomment-2273985526
    composer check-platform-reqs; \
    chown -R www-data:www-data web/sites web/modules web/themes; \
    rmdir /var/www/html; \
    ln -sf /opt/drupal/web /var/www/html; \
    # delete composer cache
    rm -rf "$COMPOSER_HOME"

ENV PATH=${PATH}:/opt/drupal/vendor/bin:/usr/bin

### Install a Drupal site ###

# Grab Railway's ENV variables
# Note: Using MYSQL_PUBLIC_URL since RAILWAY_PRIVATE_DOMAIN is not available during build time
ARG DATABASE_PUBLIC_URL
ARG DRUPAL_ADMIN_PASSWORD

WORKDIR /opt/drupal

RUN ./vendor/bin/drush site:install -y --db-url=$DATABASE_PUBLIC_URL --account-pass=$DRUPAL_ADMIN_PASSWORD --site-name="My Drupal CMS on Railway"

# vim:set ft=dockerfile:
