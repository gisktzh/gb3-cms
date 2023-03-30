FROM php:8.1.16-apache
LABEL maintainer="Andy Miller <rhuk@getgrav.org> (@rhukster)"

# Enable Apache Rewrite + Expires Module
RUN a2enmod rewrite expires && \
    sed -i 's/ServerTokens OS/ServerTokens ProductOnly/g' \
    /etc/apache2/conf-available/security.conf

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    unzip \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libyaml-dev \
    libzip4 \
    libzip-dev \
    zlib1g-dev \
    libicu-dev \
    g++ \
    git \
    cron \
    vim \
    && docker-php-ext-install opcache \
    && docker-php-ext-configure intl \
    && docker-php-ext-install intl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install zip \
    && rm -rf /var/lib/apt/lists/*

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=2'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.enable_cli=1'; \
    echo 'upload_max_filesize=128M'; \
    echo 'post_max_size=128M'; \
    echo 'expose_php=off'; \
    } > /usr/local/etc/php/conf.d/php-recommended.ini

# not compatible with PHP 8.1.16
#RUN pecl install apcu \
#    && pecl install yaml-2.0.4 \
#    && docker-php-ext-enable apcu yaml

# Set user to www-data
RUN chown www-data:www-data /var/www
USER www-data

# Define Grav specific version of Grav or use latest stable
ARG GRAV_VERSION=latest

# Install grav
WORKDIR /var/www
RUN curl -o grav-admin.zip -SL https://getgrav.org/download/core/grav-admin/${GRAV_VERSION} && \
    unzip grav-admin.zip && \
    mv -T /var/www/grav-admin /var/www/html && \
    rm grav-admin.zip

# Create cron job for Grav maintenance scripts
RUN (crontab -l; echo "* * * * * cd /var/www/html;/usr/local/bin/php bin/grav scheduler 1>> /dev/null 2>&1") | crontab -



# Install CORS plugin
WORKDIR /var/www/html
RUN bin/gpm install CORS

# Return to root user
USER root

# File copying
# Copy folders to temporary folder to setup default creation in entrypoint
RUN mkdir -p /.docker/grav_defaults
COPY data/accounts /.docker/grav_defaults/user/accounts
COPY data/data /.docker/grav_defaults/user/data
COPY .docker/entrypoint.sh /.docker/entrypoint.sh
RUN chmod -R 777 /.docker

# Copy Grav system folders
# These are all the folders that are NOT (or should not be) controlled at runtime
COPY --chown=www-data:www-data system /var/www/html/user


# Setup symlinks for all directories that contain data controlled at runtime (i.e. our "database")
# Create rootdirectory where our symlinked data shall reside
RUN mkdir /cms_data

# Move folders that should be backupped to rootdirectory and set up symlinks
RUN mkdir -p /cms_data/user/data &&  \
    chown www-data:www-data /cms_data/user/data &&  \
    mv /var/www/html/user/data /cms_data/user &&  \
    ln -s /cms_data/user/data /var/www/html/user

RUN mkdir -p /cms_data/user/accounts &&  \
    chown www-data:www-data /cms_data/user/accounts &&  \
    mv /var/www/html/user/accounts /cms_data/user &&  \
    ln -s /cms_data/user/accounts /var/www/html/user

# pages is not actually needed, but might be in the future - so we do not forget
RUN mkdir -p /cms_data/user/pages &&  \
    chown www-data:www-data /cms_data/user/pages &&  \
    mv /var/www/html/user/pages /cms_data/user &&  \
    ln -s /cms_data/user/pages /var/www/html/user

RUN mkdir /cms_data/assets &&  \
    chown www-data:www-data /cms_data/assets &&  \
    mv /var/www/html/assets /cms_data &&  \
    ln -s /cms_data/assets /var/www/html

RUN mkdir /cms_data/backup &&  \
    chown www-data:www-data /cms_data/backup &&  \
    mv /var/www/html/backup /cms_data &&  \
    ln -s /cms_data/backup /var/www/html

ENTRYPOINT ["bash", "-c", "/.docker/entrypoint.sh /.docker/grav_defaults/user/"]