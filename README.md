# Laravel 5 Installation script (debian distros)
This script checks for the basic requirements and then install the fresh copy of laravel

## Setup
Check the GLOBAL VARIABLES in installation.config file and change it for your project

**GLOBAL VARIABLES**
```
PHP_REQUIRED_VERSION="7.1.0"
LARAVEL_VERSION="5.6"
INSTALL_DIRECTORY="/var/www/html/"
VIRTUAL_HOST="laravel.local"
PROJECT_NAME="laravel"
EMAIL="webmaster@localhost"
```

## What it script does
- Installs Apache 2, PHP 7.1 & MySQL if not already installed
- Checks if PHP is installed
- Checks if PHP version is above the requirement for laravel installation
- Checks if the required PHP extensions are enabled
- Checks and installs composer if not installed
- Install a fresh copy of laravel
- Set needed permissions for files and folders of laravel
- Create Apache 2 Virtual Host
