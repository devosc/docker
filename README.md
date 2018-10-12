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
echo "127.0.0.1 mvc5playground" | sudo tee -a /etc/hosts
```
Copy the `traefik.toml` file and set your `acme` email address in the `traefik.toml` file for Let's Encrypt SSL certificates. 
```
cp traefik/traefik.toml.sample traefik/traefik.toml
```
Copy the `docker-compose.yml` file into the PHP project directory and set the build `context` path to the location of the Docker directory.
```
build:
  context: ~/docker
```
Also set the `container_name` and frontend `Host` variables to the name of the project in the `docker-compose.yml` file.
```
container_name: mvc5playground
labels:
  - traefik.frontend.rule=Host:mvc5playground
```
Start the project container and proxy service (Traefik).
```
docker-up -a
```

## Project Commands
Each project has its own `docker-compose.yml` file and should use the same build context, e.g `~/docker`.
- Start: `docker-up`
- Stop: `docker-down`
- Start with services: `docker-up -a`   
- Stop all services: `docker-down -a`
- App User: `docker-app`
- Root User: `docker-root`
- Composer: `docker-composer`
- NPM: `docker-npm`
- PHPUnit: `docker-phpunit`
- Xdebug: `docker-xdebug [on|off]`
- Logs: `docker-logs`

## Build Args
To use a specific (Apache) PHP Docker image, set the `RELEASE_VERSION` build argument in the `docker-compose.yml` file. To install Xdebug, set `XDEBUG` to true.
```
args:
  - XDEBUG=false
  - RELEASE_VERSION=7.2-apache
```
