# PHP Docker Project
The `PHP Docker Project` is a toolkit for developing PHP web applications using Docker. Each project contains a Compose file that uses the same build context and provides its own container build arguments, e.g. the version of PHP to use and the development tools to install. In order to run multiple projects at the same time, [Traefik](https://traefik.io/) is used as a reverse proxy. Shared services, such as Adminer, MailHog and PostgreSQL, can be started at the same time as a project container using the command `docker-up -a`. Other commands are available to provide a convenient way to work with a PHP project and Docker, e.g. `docker-app`, `docker-artisan` and `docker-xdebug`.
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
Run the `install` script to create the `.build.env`,  `services` and `traefik.toml` files.
```
./install
```
Or manually copy and configure the files.
#### Manual Configuration
Create a self signed SSL certificate and copy the sample `traefik.toml` file.
```
traefik/create-cert && \
cp traefik/traefik-sample.toml traefik/traefik.toml
```
Copy the sample `services` script file to manage the shared services, e.g. Traefik, MariaDB, PostgreSQL, MailHog and Adminer.
```
cp services-sample services
```
Copy the sample `.build.env` file, set the user id, group id, locale, time zone and database root password.
```
cp .build-sample.env .build.env
```
## Add Docker Compose File To PHP Project
Copy the `docker-compose.yml` file into the PHP project directory and set the build `context` path to the location of the `~/docker` directory.
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
Mount the project directory path to `/var/www`. The document root is `/var/www/public`.
```
volumes:
  - .:/var/www
```
[ Optional ] To use your `ssh` keys to connect to a git repository, mount your `.ssh` directory to the `app` user's home directory.
```
volumes:
  - ~/.ssh:/home/app/.ssh
```
## Start Project Container
Inside the project directory, start the project container and the shared services.
```
docker-up -a
```

## Project Commands
- Start container: `docker-up`
- Stop container: `docker-down`
- Start container with services: `docker-up -a`   
- Stop container and all services: `docker-down -a`
- App User: `docker-app`
- Root User: `docker-root`
- Artisan: `docker-artisan`
- CakePHP: `docker-cakephp`
- Composer: `docker-composer`
- Git: `docker-git`
- Logs: `docker-logs`
- npm: `docker-npm`
- PHPUnit: `docker-phpunit`
- Symfony: `docker-symfony [phpunit]`
- WP-CLI: `docker-wp`
- Xdebug: `docker-xdebug [on|off]`
    - Start remote debugging session `--session-start`
    - Stop remote debugging session `--session-stop`
    - IDE key `--idekey NAME`
    - Remote port `--remote-port PORT`
    - Profiler on `--profiler-on`
    - Profiler off `--profiler-off`
    - Profiler output directory `--profiler-output-dir PATH`

## PHP Command
The `docker-php` command provides a command line interface for PHP, Composer and Git. PHP is the default command and it runs an interactive shell when no arguments exist. Use `docker-php PATH` to execute a file relative to the project directory and use `--ssh-keys` to mount your `.ssh` directory when using Composer and Git. Use the `CLI_RELEASE_VERSION` build argument to change the PHP Docker image version. To install Xdebug, set `XDEBUG=true` in the `.build.env` file, or create a separate `.build-cli.env`.

## Build Args
To use a specific `stretch/apache` [PHP Docker image](https://hub.docker.com/_/php/), set the `RELEASE_VERSION` build argument in the `docker-compose.yml` file. To install Xdebug and npm, set their attributes to true.
```
args:
  - XDEBUG=true
  - NODE_JS=true
  - RELEASE_VERSION=apache
```
There are other build arguments available for Composer, WP-CLI, the document root, user and group. Trailing URL slashes can be removed and the Apache log level can be set to debug.
```
  - COMPOSER=true
  - WP_CLI=false
  - DOCUMENT_ROOT=/var/www/html
  - APACHE_LOG_LEVEL=debug
  - REDIRECT_TRAILING_SLASH=false
  - WWW_USER=app
  - WWW_GROUP=app
```
## Build Environment Variables
Use the variables `USER_ID`, `GROUP_ID`, `LOCALE` and `TIME_ZONE` to match the file permissions, locale and time zone between the container and the host. The variables are automatically detected and stored in the file `.build.env` in the `~/docker` directory by the `install` script. These environment variables are sourced prior to building a container and running the project commands.
```
args:
  - USER_ID=${USER_ID}
  - GROUP_ID=${GROUP_ID}
  - LOCALE=${LOCALE}
  - TIME_ZONE=${TIME_ZONE}
```
## PHP Build Variables
The following variables are available to customize the PHP build for a container. The variables can be configured in the project Compose file or the `.build.env` file. A semicolon can be used to separate the arguments for multiple `docker-php-ext-configure` commands.
```
args:
  - BUILD_DEPS=${BUILD_DEPS}
  - PHP_EXT_CONFIGURE=${PHP_EXT_CONFIGURE}
  - PHP_EXT_INSTALL=${PHP_EXT_INSTALL}
```
## Rebuild Images
Use `docker-up --build` to build the images after changing a `Dockerfile` or the `docker-compose.yml` file. Use `docker-down --remove-images` to remove the project images.
## Shared Services
Shared services, such as Traefik and MailHog, are automatically started using `docker-up -a`. The `-a` switch runs `docker-services up` which calls the `services` script that manages the services to start. To stop all services, it is easier to stop and remove all containers using `docker-down -a`, this is because multiple services can be connected to a shared service. If there are no projects running, then it is possible to use `docker-services down`. An individual service can be targeted by specifying its name, e.g. `docker-services adminer up`, and the image for the service can be built before starting its container using the `--build` switch, e.g. `docker-services adminer up --build`. Similarly, the image for a service can be removed when stopping the service, e.g `docker-services adminer down --remove-images`. The i.p. address for a particular service can also be retrieved, e.g. `docker-services mariadb ip-address`.
## Local Services
Other services can be added to the `local` directory and registered in the `services` script. A `local` service will be used instead of a core service, if it exists. A service can be defined in a Compose file matching the name of the service, e.g. `mysql.yml`. Alternatively, a service can be a directory matching the name of the service, containing a `docker-compose.yml` file.
## Trusted Proxy Server Configuration
If necessary, use `docker-traefik ip-address` to return the i.p. address for trusted proxy server configurations.
## Demo Applications
CakePHP, Laravel, Mvc5, Symfony, and WordPress demo applications can be installed into the `~/docker/www` directory.
```
docker-create-project [cakephp|laravel|multisite-convert|mvc5|phpinfo|symfony|wordpress]
```
The URL is `https://docker-project`.
