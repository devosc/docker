# PHP Docker (Development) Environment

## Install
Download the Docker project into your home directory and add the directory `~/docker/bin` to your system path. 
```
cd ~/docker
```
```
echo "export PATH=$PATH:$(pwd)/bin" | tee -a ~/.profile && source ~/.profile
```
Add the project name to your `/etc/hosts` file.
```
echo "127.0.0.1 docker-project" | sudo tee -a /etc/hosts
```
Copy the sample `traefik.toml` file and set the `acme` email address for Let's Encrypt SSL certificates. 
```
cp traefik/traefik.toml.sample traefik/traefik.toml
```
Copy the sample `services` script file. This file can be edited to manage the shared services.
```
cp services.sample services
```
## Add Docker Compose File To PHP Project
Copy the `docker-compose.yml` file into the PHP project directory and set the build `context` path to the location of the Docker directory.
```
build:
  context: ~/docker
```
Set the `container_name` and frontend `Host` variables to the name of the project.
```
container_name: docker-project
labels:
  - traefik.frontend.rule=Host:docker-project
```
Mount the project directory path to `/var/www`. The web server document root is `/var/www/public` by default.
```
volumes:
  - .:/var/www
```
## Start Project Container
Inside the project directory, start the project container and proxy service (Traefik).
```
docker-up -a
```

## Project Commands
Each project has its own `docker-compose.yml` file and should use the same build context, e.g `~/docker`.
- Start container: `docker-up`
- Stop container: `docker-down`
- Start container with services: `docker-up -a`   
- Stop container and all services: `docker-down -a`
- App User: `docker-app`
- Root User: `docker-root`
- Composer: `docker-composer`
- npm: `docker-npm`
- PHPUnit: `docker-phpunit`
- Xdebug: `docker-xdebug [on|off]`
- Logs: `docker-logs`

## Build Args
To use a specific `stretch/apache` [PHP Docker image](https://hub.docker.com/_/php/), set the `RELEASE_VERSION` build argument in the `docker-compose.yml` file. To install Xdebug, set `XDEBUG` to true.
```
args:
  - XDEBUG=false
  - RELEASE_VERSION=7.2-apache
```
There are other build arguments for Composer, npm and the web server document root. The user and group for the web server can also be configured.
```
  - COMPOSER=true
  - NODE_JS=true
  - DOCUMENT_ROOT=/var/www/html
  - WWW_USER=app
  - WWW_GROUP=app
```

## Rebuild Images
After changing a Dockerfile or the `docker-compose.yml` file for a project, use `docker-up --build` to build the images before starting the containers. Use `docker-down --remove-images` to remove all local project images, and add `-a` at the end to stop the proxy service.
