# Introduction
Grav is a modern open source flat-file CMS. This repository contains the official Docker Image for Grav and was modified to fit the requirements of GB3.

This docker image is currently pretty minimal and uses:

* apache-2.4.56
* GD library
* Unzip library
* php8.1.17
* php8.1.17-opcache
* php8.1.17-yaml
* cron
* vim editor

# Getting Started

Original dockerfile from: https://github.com/getgrav/docker-grav

See https://getgrav.org/ for more information.

## Overall setup

This setup is customized around Grav's filesystem-based approach. For persistence, we need to backup

* `user/accounts`: Holds all accounts that have access to grav
* `user/data`: Holds the data of flex-objects
* `user/pages`: Although currently not needed, users might create pages and these need to be backupped
* `assets`: Holds user-provided files like thumbnails
* `backup`: Holds the backups that are generated by grav

In order for this to work, these directories are placed inside a rootfolder in our container, named `/cms_data`. This
folder is then symlinked to the actual `/var/www/html/cms` folder where Grav resides. Through this, all changes to any of
the symlinked folders' data will be made in the root folder. This root folder should be used as a Docker volume and
allows for backups.

Since we need to provide initial data (e.g. initial users or initial topics), the Docker entrypoint file checks for the
existence of these files and only copies them if they do not exist.

## Building the image from Dockerfile

```shell
docker build -t gb3-grav-cms:latest .
```

To build a docker image within a proxy you can use the following command instead:

```shell
docker build --build-arg http_proxy=http://<proxy_ip>:<proxy_port> --build-arg https_proxy=https://<proxy_ip>:<proxy_port> -t gb3-grav-cms:latest .
```
You only need to replace `proxy_ip` and `proxy_port`

### Docker build arguments
* `subfolder` (Optional, Default: `/cms`) Moves the entire CMS content from the root folder into the given subfolder; used if the base URL does contain a sub domain, e.g. https://maps.zh.ch/cms 

## Running Grav image:

```shell
docker run -p 8080:80 -v nameOfMyVolume:/cms_data --name gb3-grav-cms gb3-grav-cms:latest
```

Example: `docker run -p 8080:80 -v grav-data:/cms_data --name gb3-grav-cms gb3-grav-cms:latest`

Point browser to `http://localhost:8080/cms/admin` and login as a user account (see Keepass for the default passwords)

# Development

To add new features to Grav it's easiest if you start the container using **docker-compose**. This binds all important data 
to your local development folders (./data and ./system). **Note:** If you add data, this will be synced as well; so be
careful when committing changes.

### Running Grav Image with docker-compose

```shell
docker-compose up -d -f ./docker-compose.yml
```

Docker compose will create two images:
* `all-grav-data` points to the CMS root folder containing all Grav data
* `grav-data` points to a small subset of Grav data that is usually used in a productive environment to backup all important files.

Point browser to `http://localhost:8080/admin` and login as a user account (see Keepass for the default passwords)

# Deployment

The deployment takes one volume to persist user data - this volume is mapped to the container's `/cms_data`.

To run this locally:
```shell
docker run -p 8080:80 -v nameOfVolume:/cms_data --name gb3-grav-cms gb3-grav-cms:latest
```

Example: `docker run -p 8080:80 -v grav-data:/cms_data --name gb3-grav-cms gb3-grav-cms:latest`

This command will boot the container and mount two local folders for synchronizing data.