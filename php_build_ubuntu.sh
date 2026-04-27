#!/bin/bash
# php_build_ubuntu.sh - script to compile PHP 8 for Ubuntu testing.

# Copyright (c) 2019-2026 Maulik Mistry mistry01@gmail.com
#
# Author: Maulik Mistry
# Please share support: https://www.paypal.com/paypalme/m1st0
#                       https://venmo.com/code?user_id=3319592654995456106&created=1753283702
# License: BSD License 2.0

# Using BASH_SOURCE for better path reliability in Bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "${SCRIPT_DIR}/bash_color_printf.sh"

# Desired PHP branch if not using git tag autodetection
PHP_VERSION="8.5.1"

# I like to setup thing here so that it doesn't bother Kubuntu/Ubuntu
PHP_DIR="/usr/local"

# Stop execution if things fail to move forward.
set -e

## DEPENDENCIES

messenger_std "Installing dependencies...";
# Add any missing needs from configuration area
#sudo apt update
#sudo apt upgrade
#sudo apt clean
sudo apt install libldap2-dev \
  libldap-common \
  libtool-bin \
  libzip-dev \
  lbzip2 \
  libxml2-dev \
  bzip2 \
  re2c \
  libbz2-dev \
  apache2-dev \
  libjpeg-dev \
  libxpm-dev \
  libxpm-dev \
  libgmp-dev \
  libgmp3-dev \
  libmcrypt-dev \
  libpspell-dev \
  librecode-dev \
  libcurl4-openssl-dev \
  libxft-dev \
  libonig-dev \
  libsqlite3-dev \
  ccache

if dpkg -l | grep -q '^ii  mysql-server'; then
  messenger_std "MySQL server detected. Using MySQL."
  USE_MYSQL=1
elif dpkg -l | grep -q '^ii  mariadb-server'; then
  messenger_std "MariaDB server detected. Using MariaDB."
  USE_MARIADB=1
else
  messenger_end "No MySQL or MariaDB found. Cannot install database dependencies."
  exit 1
fi

if [ "$USE_MYSQL" = "1" ]; then
  sudo apt install libmysqlclient-dev
elif [ "$USE_MARIADB" = "1" ]; then
  sudo apt install libmariadb-dev
fi
messenger_end "Done installing dependencies."

messenger_std "Setting up LDAP dependency recognition...";
if [[ ! -e /usr/lib/libldap.so ]]; then
  sudo ln -sf /usr/lib/x86_64-linux-gnu/libldap.so /usr/lib/libldap.so
fi

if [[ ! -e /usr/lib/liblber.so ]]; then
  sudo ln -sf /usr/lib/x86_64-linux-gnu/liblber.so /usr/lib/liblber.so
fi

if [[ ! -e /usr/include/gmp.h ]]; then
  sudo ln -sf /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h
fi
messenger_end "Done with LDAP setup."

## CONFIGURE

if [ -d ./php-src ]; then
  cd ./php-src 
  git reset --hard HEAD
  git fetch --tags --force
  
  # Check if we are already on the desired tag
  if [ "$(git describe --tags --exact-match 2>/dev/null)" != "php-${PHP_VERSION}" ]; then
    git checkout "php-${PHP_VERSION}" 2>/dev/null || git checkout -b "PHP-${PHP_VERSION}" "php-${PHP_VERSION}"
  else
    messenger_std "Already on php-${PHP_VERSION}"
  fi

  ## Obtain latest tag ##
  # Sometimes the latest tag is not properly found using either of the following
  # or we don't want the latest Release Candidate
  #tag=$(git describe --tags `git rev-list --tags --max-count=1`)
  tag=$(git describe --tags `git rev-list --branches --max-count=1`)
  if [ "$tag" != "php-${PHP_VERSION}" ]; then
    git switch --create ${tag} ${tag}
  fi
else
  git clone https://github.com/php/php-src
  cd ./php-src
  tag=$(git describe --tags `git rev-list --branches --max-count=1`)
  git checkout tags/$tag -b $tag
  #git switch --create PHP-${PHP_VERSION} php-${PHP_VERSION}
fi

messenger_std "Running 'buildconf' ..."
# Helped fix configure issues and ignored files needing an update
./buildconf --force
messenger_end "Done 'buildconf' ."

## CONFIGURE

messenger_std "Running 'configure' ..."
# Compile options
export CC="ccache gcc" && export CXX="ccache g++"
./configure --prefix="$PHP_DIR/php8" \
    --with-config-file-path="$PHP_DIR/php8/etc/" \
    --with-config-file-scan-dir="$PHP_DIR/php8/etc/conf.d/" \
    --enable-mbstring \
    --with-zip \
    --enable-bcmath \
    --enable-pcntl \
    --enable-ftp \
    --enable-exif \
    --enable-calendar \
    --enable-sysvmsg \
    --enable-sysvsem \
    --enable-sysvshm \
    --enable-intl \
    --enable-zts \
    --with-curl \
    --with-iconv \
    --with-gmp \
    --with-pspell \
    --with-zlib-dir=/usr \
    --enable-gd-jis-conv \
    --with-openssl \
    --with-gettext=/usr \
    --with-zlib=/usr \
    --with-bz2 \
    --with-apxs2=/usr/bin/apxs \
    --with-ldap \
    --with-mysql=mysqlnd \
    --with-mysqli=mysqlnd \
    --with-pdo-mysql=mysqlnd \
    --with-xdebug
 #   --with-mcrypt \
 #   --enable-wddx \
 #   --with-gd \
 #   --with-jpeg-dir=/usr \
 #   --with-png-dir=/usr \
 #   --with-xpm-dir=/usr \
 #   --with-freetype-dir=/usr \
 #   --enable-gd-native-ttf \
 #   --with-recode=/usr \
 #   --without-xml

 messenger_end "Done with 'configure' ."

## COMPILE

messenger_std "Cleaning previous failures with 'make clean' ..."
make clean
messenger_end "Done wit 'make clean' ."

messenger_std "Running 'make' ..."
CPUNUM=`nproc`
make -j ${CPUNUM}
messenger_end "Done with 'make' ."

messenger_std "Running 'make install' ..."
sudo make install
messenger_end "Done with 'make install' ."

# Update paths for easy switching
sudo update-alternatives --install /usr/bin/php php $PHP_DIR/php8/bin/php 50 \
  --slave /usr/share/man/man1/php.1.gz php.1.gz \
  $PHP_DIR/php8/php/man/man1/php.1

messenger_std "Select the version of PHP you want active in subsequent shells and the system:"
sudo update-alternatives --config php

## APACHE SETUP

# Provide Apache2 libphp.so for later configuration
messenger_std "Running 'libtool --finish ./libs' ..."
libtool --finish ./libs
sudo mkdir -p "$PHP_DIR/php8/lib/apache2/modules"
sudo cp "./libs/libphp.so" "$PHP_DIR/php8/lib/apache2/modules/"
messenger_end "Done running 'libtool' ."

# Left unconfigured between Apache2 vs CLI
sudo mkdir -p "$PHP_DIR/php8/etc/"
sudo cp "php.ini-development" "$PHP_DIR/php8/etc/"
sudo cp "php.ini-production" "$PHP_DIR/php8/etc/"

# messenger_std "Enable non-threaded mpm_worker module..."
#sudo a2dismod mpm_worker
#sudo a2enmod mpm_prefork
# messenger_end "Done with mpm_worker module."

messenger_std "Enable threaded --enable-zts mpm_prefork module..."
sudo a2dismod mpm_prefork
sudo a2enmod mpm_worker
messenger_end "Done with mpm_prefork module."

PHP_MODULE_CONF="/etc/apache2/mods-available/php8.conf"
if [[ ! -e "$PHP_MODULE_CONF" ]]; then
  sudo tee "$PHP_MODULE_CONF" > /dev/null <<EOF
<IfModule php_module>
  <FilesMatch ".+\.ph(ar|p|tml)$">
    SetHandler application/x-httpd-php
  </FilesMatch>
  <FilesMatch ".+\.phps$">
    SetHandler application/x-httpd-php-source
    
    # Deny access to raw php sources by default
    # To re-enable it's recommended to enable access to the files
    # only in specific virtual host or directory
    Require all denied
  </FilesMatch>

  # Deny access to files without filename (e.g. '.php')
  <FilesMatch "^\.ph(ar|p|ps|tml)$">
    Require all denied
  </FilesMatch>
</IfModule>
EOF

fi

PHP_MODULE_LOAD="/etc/apache2/mods-available/php8.load"
if [[ ! -e "$PHP_MODULE_LOAD" ]]; then
  sudo tee "$PHP_MODULE_LOAD" > /dev/null <<EOF
LoadModule php_module $PHP_DIR/php8/lib/apache2/modules/libphp.so
EOF

fi

messenger_std "Disable old and enable new $tag module..."
sudo a2dismod php
sudo a2enmod php8
messenger_end "Done with script module enablement."

messenger_std "Restarting Apache Web server..."
sudo systemctl restart apache2
sudo systemctl status apache2
messenger_end "Done script restarting Apache Web server."

messenger_end "Done. Any errors starting Apache2 with PHP can be seen with 'sudo journalctl -xe' ."

# An example:
# 
# Running PHP scripts in user directories is disabled by default
# 
# You may commnt this out as needed in conf files at
# /etc/apache2/mods-available/
# to re-enable PHP in user directories
# from <IfModule> to </IfModule>
#
#<IfModule mod_userdir.c>
#    <Directory /home/*/public_html>
#        php_admin_flag engine Off
#    </Directory>
#</IfModule>"

# Return to reprevious location
cd -
