# PHP Docker (Development) Environment

## Install
Download or clone the Docker project into your home directory.
```
git clone git@github.com:devosc/docker.git
```
Add the directory `~/docker/bin` to your system path. Change `.profile` to `.zshrc` if necessary.
```
echo 'export PATH=$PATH:~/docker/bin' | tee -a ~/.profile && source ~/.profile
```
Add the project name to your `/etc/hosts` file.
```
echo "127.0.0.1 docker-project" | sudo tee -a /etc/hosts
```
#### Configuration Installer
Run the `install` script to copy the `services` file and to configure the `traefik.toml` file.
```
./install --email hello@example.com
```
Or alternatively, manually copy and configure the files.
#### Manual Configuration
Copy the sample `traefik.toml` file and set the `acme` email address for Let's Encrypt SSL certificates. 
```
cp traefik/traefik.toml.sample traefik/traefik.toml
```
Copy the sample `services` script file to manage the shared services, e.g. Traefik, MariaDB, Postgres and MailHog.
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
Inside the project directory, start the project container and the shared services.
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
To use a specific `stretch/apache` [PHP Docker image](https://hub.docker.com/_/php/), set the `RELEASE_VERSION` build argument in the `docker-compose.yml` file. To install Xdebug and npm, set their attributes to true.
```
args:
  - XDEBUG=true
  - NODE_JS=true
  - RELEASE_VERSION=apache
```
There are other build arguments available for Composer, WP-CLI, npm, the web server document root, user and group. Trailing url slashes can also be removed.
```
  - COMPOSER=true
  - WP_CLI=false
  - DOCUMENT_ROOT=/var/www/html
  - REDIRECT_TRAILING_SLASH=false
  - WWW_USER=app
  - WWW_GROUP=app
```
## Build Environment Variables
To match the file permissions and time zone between the container and the host, use the environment variables `USER_ID`, `GROUP_ID` and `TZ`. These environment variables are automatically detected and stored in the file `.build.env` in the docker directory, if the file does not already exist. These environment variables are sourced prior to building a container and running any of the project commands.
```
args:
  - USER_ID=${USER_ID}
  - GROUP_ID=${GROUP_ID}
  - TZ=${TZ}
```
## Rebuild Images
After changing a `Dockerfile` or the `docker-compose.yml` file for a project, use `docker-up --build` to build the images before starting the containers. Use `docker-down --remove-images` to remove all the local project images and add `-a` at the end to stop the shared services.
## Demo Applications
WordPress, Symfony, Laravel and Mvc5 demo applications can be installed into the docker `www` directory.
```
docker-create-project [wordpress|symfony|laravel|phpinfo|mvc5]
```
The url is `https://docker-project`. To get the i.p. address for the trusted proxy server configurations use `docker-traefik ip-address` .
