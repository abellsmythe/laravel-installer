#!/bin/bash

# LOAD CONFIG

SCRIPTPATH=$(cd ${0%/*} && pwd -P)
source $SCRIPTPATH/installation.config

# VERIFY ROOT PERMISSION

if [ "$(whoami)" != 'root' ]; then
	echo -e "You have no permission to run $0 as non-root user. Use sudo"
		exit 1;
fi

# SWAPING SPACE CONFIGURATION

echo "Swaping space configuration"
dd if=/dev/zero of=/swap bs=1M count=2048;mkswap /swap;swapon /swap;echo "/swap swap swap defaults 0 0" >> /etc/fstab

# CLEAN WINDOW

clear

# INSTALL APACHE2, PHP 7.1 & MySQL

echo -n "Do you want to install Apache 2, PHP 7.1 & MySQL? [Yes or No]: "
read yn
case "$yn" in
	"Yes") 
		echo "Updating repository"
		apt-get update

		echo "Installing Apache 2"
		apt-get install -y apache2

		echo "Installing MySQL"
		apt-get install -y mysql-server
		mysql_secure_installation

		echo -e "Installing PHP 7.1"
		apt-get install -y php7.1 php7.1-mbstring php7.1-mcrypt php7.1-xml php-pear
		apt-get install -y php7.1-mysql
		apt-get install -y libapache2-mod-php7.1

		a2enmod rewrite
		service apache2 restart
		;;
	*) 
		;;
esac

# CHECK PHP INSTALLATION

if ! type "php" > /dev/null; then
  echo -e "${RED}You don't have php installed, please install PHP first and then try again${NO_COLOR}"
  exit 1;
fi

# CHECK PHP VERSION

PHP_VERSION=$(php -v | grep -P -o -i "PHP (\d+\.\d+\.\d+)" | tr -d "\n\r\f" | sed 's/PHP //g' )

if [[ $PHP_VERSION < $PHP_REQUIRED_VERSION ]]; then
	echo -e "${RED}You need to upgrade your PHP version to work with Laravel. Required version: $PHP_REQUIRED_VERSION ${NO_COLOR}"
	exit 1;
fi

# CHECK PHP EXTENSIONS

if ! [ "$(php -m | grep -c 'mbstring')" -ge 1 ]; then
	echo -e "${RED}Please enable 'mbstring' php extension to proceed${NO_COLOR}"
	exit 1;
fi 

if ! [ "$(php -m | grep -c 'PDO')" -ge 1 ]; then
	echo -e "${RED}Please enable 'PDO' php extension to proceed${NO_COLOR}"
	exit 1;
fi 

if ! [ "$(php -m | grep -c 'openssl')" -ge 1 ]; then
	echo -e "${RED}Please enable 'openssl' php extension to proceed${NO_COLOR}"
	exit 1;
fi 

if ! [ "$(php -m | grep -c 'tokenizer')" -ge 1 ]; then
	echo -e "${RED}Please enable 'tokenizer' php extension to proceed${NO_COLOR}"
	exit 1;
fi 

# CHECK COMPOSER INSTALLATION

if ! type "composer" > /dev/null; then
  	echo -e "${RED}You don't have Composer installed.${NO_COLOR}"
  	echo "Do you want to install composer?"
	select yn in "Yes" "No"; do
	    case "$yn" in
	        "Yes") 
				echo -e "${GREEN}Installing Composer...${NO_COLOR}"

				php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
				php composer-setup.php
				php -r "unlink('composer-setup.php');"
				mv composer.phar /usr/local/bin/composer
				;;
	        *) 
				echo -e "${RED}You need to install composer to proceed.${NO_COLOR}"
				exit 1
				;;
	    esac
	done
fi

if [[ ! $PROJECT_NAME ]]; then
	echo -n "Enter a project name: "
	read PROJECT_NAME
fi

# CREATE PROJECT

cd ${INSTALL_DIRECTORY}
composer create-project --prefer-dist laravel/laravel ${PROJECT_NAME} ${LARAVEL_VERSION}
if [ -e "$INSTALL_DIRECTORY$PROJECT_NAME" ]; then
	echo -e "${GREEN}Laravel project ${PROJECT_NAME} created${NO_COLOR}"
else
	echo -e "${RED}There is an error creating the project${NO_COLOR}"
	exit;
fi
chown -R www-data.www-data ${INSTALL_DIRECTORY}${PROJECT_NAME} 
chmod -R 755 ${INSTALL_DIRECTORY}${PROJECT_NAME}
chmod -R 775 ${INSTALL_DIRECTORY}${PROJECT_NAME}/storage
chmod -R 775 ${INSTALL_DIRECTORY}${PROJECT_NAME}/bootstrap/cache


# CHECK IF DOMAIN ALREADY EXIST
if [ -e $APACHE_DOMAIN ]; then
	echo -e "${RED}This domain already exists.\nPlease Try Another one${NO_COLOR}"
	exit;
fi

# CREATE VIRTUAL HOST FILE

if ! echo "
<VirtualHost *:80>
	ServerAdmin $EMAIL
	ServerName $VIRTUAL_HOST
	ServerAlias $VIRTUAL_HOST
	DocumentRoot $INSTALL_DIRECTORY$PROJECT_NAME
	<Directory $INSTALL_DIRECTORY$PROJECT_NAME>
		Options Indexes FollowSymLinks MultiViews
		AllowOverride all
		Require all granted
	</Directory>
	ErrorLog /var/log/apache2/$VIRTUAL_HOST-error.log
	LogLevel error
	CustomLog /var/log/apache2/$VIRTUAL_HOST-access.log combined
</VirtualHost>" > $APACHE_DOMAIN
then
	echo -e "${RED}There is an error creating $VIRTUAL_HOST file${NO_COLOR}"
	exit;
else
	echo -e "${GREEN}\nNew Virtual Host Created\n${NO_COLOR}"
fi

# ADD DOMAIN IN /etc/hosts

if ! [ echo "127.0.0.1	$APACHE_DOMAIN" >> /etc/hosts ]; then
	echo -e "${RED}Not able to write in /etc/hosts${NO_COLOR}"
	exit;
else
	echo -e "${GREEN}Host added to /etc/hosts file \n${NO_COLOR}"
fi

# ENABLE VIRTUAL HOST

a2ensite $APACHE_DOMAIN

# RELOAD APACHE CONFIGURATION

service apache2 reload

# SHOW MESSAGE

echo -e "${GREEN}Everything is ready mate! Your new host is: http://$APACHE_DOMAIN create something awesome!${NO_COLOR}"

# NOTIFICATION

notify-send "${VIRTUAL_HOST} was correctly setup!"

# COPYRIGHT

echo -e "\n\tMade with ${LIGHT_RED}${BOLD}<3${NORMAL}${NO_COLOR} by ${LIGHT_CYAN}Alton Bell Smythe${NO_COLOR} - https://abellsmythe.me\n"

exit;