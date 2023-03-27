# Introduction
Grav is a modern open source flat-file CMS. This repository contains the official Docker Image for Grav and was modified to fit the requirements of GB3.

This docker image is currently pretty minimal and uses:

* apache-2.4.38
* GD library
* Unzip library
* php8.1.16
* php8.1.16-opcache
* php8.1.16-yaml
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
docker run -p 8080:80 `
  --mount type=bind,source="C:\tmp\grav\accounts",target=/var/www/html/user/accounts `
  --mount type=bind,source="C:\tmp\grav\data",target=/var/www/html/user/data `
  --mount type=bind,source="C:\tmp\grav\assets",target=/var/www/html/assets `
  --mount type=bind,source="C:\tmp\grav\backup",target=/var/www/html/backup `
  --name gb3-grav-cms gb3-grav-cms:latest
```

Point browser to `http://localhost:8080/admin` and login as an user account (see Keepass for the default passwords)

# Development

To add new features to Grav it's easiest if you start the container using docker-compose. This binds all important data to your local development folder (./data).

## Running Grav Image with docker-compose and a volume mapped to this local directory (./data)

```
docker-compose up -d -f ./docker-compose.yml
```

# Deployment

The deployment takes two bind mounts to persist user data:

* `/var/www/html/user/data`: Persists the actual user data content
* `/var/www/html/user/accounts`: Persists account data

In order to still provide defaults, the Dockerfile uses an entrypoint script. The entrypoint script has a list of files
that are checked on each system boot. If they exist in the mounted directory, it either means that the app has been
booted before OR that the files have been added by the users themselves. If the files do not exist, they are copied and
as such loaded by GravCMS.

To run this locally:
```powershell
docker run -p 8080:80 `
  --mount type=bind,source="C:\tmp\grav\accounts",target=/var/www/html/user/accounts `
  --mount type=bind,source="C:\tmp\grav\data",target=/var/www/html/user/data `
  --mount type=bind,source="C:\tmp\grav\assets",target=/var/www/html/assets `
  --mount type=bind,source="C:\tmp\grav\backup",target=/var/www/html/backup `
  --name gb3-grav-cms gb3-grav-cms:latest
```
This command will boot the container and mount two local folders for synchronizing data.