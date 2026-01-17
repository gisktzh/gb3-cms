FROM php:8.5.2-apache
LABEL maintainer="Andy Miller <rhuk@getgrav.org> (@rhukster)"

ARG http_proxy
ARG SUBFOLDER='/cms'

# Enable Apache Rewrite + Expires + headers Module
RUN a2enmod rewrite expires headers && \
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
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/log/apache2/*


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
    echo 'allow_url_fopen=0'; \
    echo 'opcache.enable=1'; \
    } > /usr/local/etc/php/conf.d/php-recommended.ini

# Set user to www-data
RUN chown www-data:www-data /var/www
USER www-data

# Define Grav specific version of Grav or use latest stable
ARG GRAV_VERSION=latest

# Install grav
WORKDIR /var/www
RUN curl -k -o grav-admin.zip -SL https://getgrav.org/download/core/grav-admin/${GRAV_VERSION} && \
    unzip grav-admin.zip && \
    mv -T /var/www/grav-admin /var/www/html${SUBFOLDER} && \
    rm grav-admin.zip

# Move the .htaccess_for_caching file to .htaccess in the assets/ folder to enable asset caching
COPY .apache/.htaccess_for_caching /var/www/html${SUBFOLDER}/assets/.htaccess

# Create cron job for Grav maintenance scripts
RUN (crontab -l; echo "* * * * * cd /var/www/html${SUBFOLDER};/usr/local/bin/php bin/grav scheduler 1>> /dev/null 2>&1") | crontab -


# Return to root user
USER root

# File copying
# Copy folders to temporary folder to setup default creation in entrypoint
RUN mkdir -p /.docker/grav_defaults
COPY data/accounts /.docker/grav_defaults/user/accounts
COPY data/data /.docker/grav_defaults/user/data
COPY data/pages /.docker/grav_defaults/user/pages
COPY .docker/entrypoint.sh /.docker/entrypoint.sh
RUN chmod -R 777 /.docker

# Copy Grav system folders
# These are all the folders that are NOT (or should not be) controlled at runtime
COPY --chown=www-data:www-data system /var/www/html${SUBFOLDER}/user

# Adjust /var/www/html${subfolder}/user/config/system.yaml by adding proxy settings (if any)
RUN if [ "$http_proxy" ] ; then sed -i "s|proxy_url: null|proxy_url: '$http_proxy'|g" /var/www/html${SUBFOLDER}/user/config/system.yaml ; fi

# Install CORS plugin
USER www-data
WORKDIR /var/www/html${SUBFOLDER}
RUN bin/gpm install CORS -n
USER root

# Setup symlinks for all directories that contain data controlled at runtime (i.e. our "database")
# Create rootdirectory where our symlinked data shall reside
RUN mkdir /cms_data

# Copy apache2.conf for Apache2 custom log with X-Forwarded-For
COPY .docker/apache2.conf /etc/apache2/apache2.conf

# Move folders that should be accessible through the volume to rootdirectory and set up symlinks
# REMARK: do not forget to include the following folders / files as well in '.docker/entrypoint.sh' -> DEFAULT_DIRECTORIES / DEFAULT_FILES
#         otherwise they might be missing in the volume later and lead to errors like: <"mkdir: cannot create directory '/var/log/apache2': File exists">
RUN mkdir -p /cms_data/user/data &&  \
    chown www-data:www-data /cms_data/user/data &&  \
    mv /var/www/html${SUBFOLDER}/user/data /cms_data/user &&  \
    ln -s /cms_data/user/data /var/www/html${SUBFOLDER}/user

RUN mkdir -p /cms_data/user/accounts &&  \
    chown www-data:www-data /cms_data/user/accounts &&  \
    mv /var/www/html${SUBFOLDER}/user/accounts /cms_data/user &&  \
    ln -s /cms_data/user/accounts /var/www/html${SUBFOLDER}/user

RUN mkdir -p /cms_data/user/pages &&  \
    chown www-data:www-data /cms_data/user/pages &&  \
    mv /var/www/html${SUBFOLDER}/user/pages /cms_data/user &&  \
    ln -s /cms_data/user/pages /var/www/html${SUBFOLDER}/user

RUN mkdir /cms_data/assets &&  \
    chown www-data:www-data /cms_data/assets &&  \
    mv /var/www/html${SUBFOLDER}/assets /cms_data &&  \
    ln -s /cms_data/assets /var/www/html${SUBFOLDER}

RUN mkdir /cms_data/backup &&  \
    chown www-data:www-data /cms_data/backup &&  \
    mv /var/www/html${SUBFOLDER}/backup /cms_data &&  \
    ln -s /cms_data/backup /var/www/html${SUBFOLDER}

RUN mkdir /cms_data/logs &&  \
    chown www-data:www-data /cms_data/logs &&  \
    mv /var/www/html${SUBFOLDER}/logs /cms_data &&  \
    ln -s /cms_data/logs /var/www/html${SUBFOLDER}

RUN mkdir /cms_data/apache2 &&  \
    chown www-data:www-data /cms_data/apache2 &&  \
    mv /var/log/apache2 /cms_data &&  \
    ln -s /cms_data/apache2 /var/log/apache2

ENTRYPOINT ["bash", "-c", "/.docker/entrypoint.sh /.docker/grav_defaults/"]