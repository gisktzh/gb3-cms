# Introduction
Grav is a modern open source flat-file CMS. This repository contains the official Docker Image for Grav and was modified to fit the requirements of GB3.

This docker image is currently pretty minimal and uses:

* apache-2.4.38
* GD library
* Unzip library
* php7.4
* php7.4-opcache
* php7.4-acpu
* php7.4-yaml
* cron
* vim editor

# Getting Started

Original dockerfile from: https://github.com/getgrav/docker-grav

See https://getgrav.org/ for more information.

## Building the image from Dockerfile

```
docker build -t gb3-grav-cms:latest .
```

## Running Grav Image with Latest Grav + Admin:

```
docker run -p 8080:80 gb3-grav-cms:latest
```

Point browser to `http://localhost:8000` and create user account...

## Running Grav Image with Latest Grav + Admin with a named volume (can be used in production)

```
docker run -d -p 8000:80 --restart always -v grav_data:/var/www/html gb3-grav-cms:latest
```

## Running Grav Image with docker-compose and a volume mapped to a local directory (./.grav)

```
docker-compose up -d -f ./docker-compose.yml
```

# Deployment

The deployment takes two bind mounts to persist user data:

* `/var/www/html/user/pages`: Persists the actual page content
* `/var/www/html/user/accounts`: Persists account data

In order to still provide defaults, the Dockerfile uses an entrypoint script. The entrypoint script has a list of files
that are checked on each system boot. If they exist in the mounted directory, it either means that the app has been
booted before OR that the files have been added by the users themselves. If the files do not exist, they are copied and
as such loaded by GravCMS.

To run this locally:
`docker run --mount type=bind,source="C:\tmp\grav\folder1",target=/var/www/html/user/accounts --mount type=bind,source="C:\tmp\grav\folder2",target=/var/www/html/user/pages --name gb3-cms grav-gb3/latest  `
This command will boot the container and mount two local folders for synchronizing data.