#!/bin/bash

# PHP 8 Compile #
# Author: Maulik Mistry
# Please share support: https://www.paypal.com/paypalme/m1st0
# References:
#   http://www.zimuel.it/install-php-7/
#   http://www.hashbangcode.com/blog/compiling-and-installing-php7-ubuntu
#   root-talis https://gist.github.com/root-talis/40c4936bf0287237839ccd3fdfdaec28
#
# License: BSD License 2.0
# Copyright (c) 2015-2023, Maulik Mistry
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the <organization> nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Desired PHP branch
PHP_VERSION="8.2.5"

# Recommended setup location
PHP_DIR="/usr/local"

# Stop execution if things fail to move forward.
set -e

## DEPENDENCIES

# Setup dependencies for PHP 8
# Add any missing needs from configuration area
#sudo apt-get update
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
  libmysqlclient-dev \
  mysql-server \
  mysql-common \
  libpspell-dev \
  librecode-dev \
  libcurl4-openssl-dev \
  libxft-dev \
  libonig-dev

# LDAP does not recognize these without additional symlinks
if [[ ! -e /usr/lib/libldap.so ]]; then
  sudo ln -sf /usr/lib/x86_64-linux-gnu/libldap.so /usr/lib/libldap.so
fi

if [[ ! -e /usr/lib/liblber.so ]]; then
  sudo ln -sf /usr/lib/x86_64-linux-gnu/liblber.so /usr/lib/liblber.so
fi

if [[ ! -e /usr/include/gmp.h ]]; then
  sudo ln -sf /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h
fi

## CONFIGURE

# Obtain desired branch or source; change into location
if [ -d ./php-src ]; then
  cd php-src
  git reset --hard HEAD
  git pull origin "PHP-$PHP_VERSION"
else
  # Obtain latest source
  git clone -b "PHP-$PHP_VERSION" https://github.com/php/php-src
  cd php-src
fi

# Helped fix configure issues and ignored files needing an update
./buildconf --force

# Compile options
./configure --prefix="$PHP_DIR/php8" \
    CPPFLAGS="-I/usr/include/mysql" \
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
    --with-openssl \
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

## COMPILE

# Cleanup for previous failures
make clean

# Build 
cpunum=`nproc`
make -j ${cpunum}

# Install
sudo make install

# Update paths for easy switching
sudo update-alternatives --install /usr/bin/php php $PHP_DIR/php8/bin/php 50 \
  --slave /usr/share/man/man1/php.1.gz php.1.gz \
  $PHP_DIR/php8/php/man/man1/php.1

# Provide PHP version choice
printf "Select the version of PHP you want active in subsequent shells and the \
  system:\n"
sudo update-alternatives --config php

## APACHE SETUP

# Provide Apache2 libphp.so for later configuration
printf "Running 'libtool --finish ./libs' as recommended.\n"
libtool --finish ./libs
sudo mkdir -p "$PHP_DIR/php8/lib/apache2/modules"
sudo cp "./libs/libphp.so" "$PHP_DIR/php8/lib/apache2/modules/"

# Left unconfigured between Apache2 vs CLI
sudo mkdir -p "$PHP_DIR/php8/etc/"
sudo cp "php.ini-development" "$PHP_DIR/php8/etc/"
sudo cp "php.ini-production" "$PHP_DIR/php8/etc/"

# Work on non-threaded version from configure
#sudo a2dismod mpm_worker
#sudo a2enmod mpm_prefork
# Work on threaded --enable-zts version from configure
sudo a2dismod mpm_prefork
sudo a2enmod mpm_worker

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
LoadModule php_module		$PHP_DIR/php8/lib/apache2/modules/libphp.so
EOF

fi

sudo a2dismod php
sudo a2enmod php8

# Restart Apache if all went well.
sudo systemctl restart apache2
sudo systemctl status apache2

# View any errors for Apache startup.
printf "Any errors starting Apache2 with PHP $PHP_VERSION can be seen with 'sudo journalctl -xe' .\n"

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
