#!/bin/bash

# PHP 8 Initial Compile #
# Author: Maulik Mistry
# References:
#   http://www.zimuel.it/install-php-7/
#   http://www.hashbangcode.com/blog/compiling-and-installing-php7-ubuntu
#
# License: BSD License 2.0
# Copyright (c) 2015-2021, Maulik Mistry
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


# Stop execution if things fail to move forward.
set -e

# Setup Kubuntu with other dependencies for PHP 8. Add any missing ones from
# the configure script.
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

# PHP 8 does not recognize these without additional parameters or symlinks for
# LDAP.
if [[ ! -e /usr/lib/libldap.so ]]; then
  sudo ln -sf /usr/lib/x86_64-linux-gnu/libldap.so /usr/lib/libldap.so
fi

if [[ ! -e /usr/lib/liblber.so ]]; then
  sudo ln -sf /usr/lib/x86_64-linux-gnu/liblber.so /usr/lib/liblber.so
fi

if [[ ! -e /usr/include/gmp.h ]]; then
  sudo ln -sf /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h
fi

# Obtain latest source
#git clone https://github.com/php/php-src
#cd php-src
# Checkout latest release
# Determine git checkout master | git checkout 8.1
#git checkout t origin/php-8.1
php_branch="8.1"


# Helped fix configure issues and ignored files needing an update.
./buildconf --force
# Setup compile options for Kubuntu.  If failures occur, check dependencies
# and symlink needs above. PHP ini and related configuration paths shown.
./configure --prefix="/usr/local/php8" \
    CPPFLAGS="-I/usr/include/mysql" \
    --with-config-file-path="/usr/local/php8/etc/" \
    --with-config-file-scan-dir="/usr/local/php8/etc/conf.d/" \
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
    --with-pdo-mysql=/usr \
    --with-gettext=/usr \
    --with-zlib=/usr \
    --with-bz2 \
    --with-apxs2=/usr/bin/apxs \
    --with-mysqli=/usr/bin/mysql_config \
    --with-ldap \
 #   --with-mcrypt \
 #   --enable-wddx \
 #   --with-gd \
 #   --with-jpeg-dir=/usr \
 #   --with-png-dir=/usr \
 #   --with-xpm-dir=/usr \
 #   --with-freetype-dir=/usr \
 #   --with-t1lib=/usr \
 #   --enable-gd-native-ttf \
 #   --with-recode=/usr \
 #   --without-xml
 #   --with-xdebug

# Cleanup for previous failures.
sudo make clean

# Using as many threads as possible.
cpunum=$((`cat /proc/cpuinfo | grep processor | wc -l` + 1))
sudo make -j ${cpunum}

# Install it accoridng to the configured path.
sudo make install

# NOTE: Provide Apache2 libphp.so .
libtool --finish ./libs
sudo mkdir -p "/usr/local/php8/lib/apache2/modules"
sudo cp "./libs/libphp.so" "/usr/local/php8/lib/apache2/modules/"
# NOTE: Update Apache2 to refer to new php.ini location below.
# Left unconfigured between Apache2 vs CLI.
sudo mkdir -p "/usr/local/php8/etc/"
sudo cp "php.ini-development" "/usr/local/php8/etc/"
sudo cp "php.ini-production" "/usr/local/php8/etc/"

# Work on non-threaded version
#sudo a2dismod mpm_worker
#sudo a2enmod mpm_prefork
# Work on threaded --enable-zts version
sudo a2dismod mpm_prefork
sudo a2enmod mpm_worker
# Since it is built with axps2, it sets things up correctly.
# NOTE: Add php8.load and php8.conf files for Apache2 accordingly.
sudo a2enmod php8

# Restart Apache if all went well.
sudo systemctl restart apache2
# View any errors for Apache startup.
printf "Any errors starting Apache2 with PHP8 can be seen with 'sudo journalctl -xe' .\n"

# Update the paths on th system according to Ubuntu.  Can be later removed and
# switched back.
sudo update-alternatives --install /usr/bin/php php /usr/local/php8/bin/php 50 \
  --slave /usr/share/man/man1/php.1.gz php.1.gz \
  /usr/local/php8/php/man/man1/php.1

# Choose your PHP version.
printf "Select the version of PHP you want active in subsequent shells and the \
  system:\n"
sudo update-alternatives --config php

## To help enable Apache 2.4 use of PHP 8. Enable this after writing the file.
## /etc/apache2/mods-available/php8.conf
#<FilesMatch ".+\.ph(p[3457]?|t|tml)$">
#    SetHandler application/x-httpd-php
#</FilesMatch>
#<FilesMatch ".+\.phps$">
#    SetHandler application/x-httpd-php-source
#    # Deny access to raw php sources by default
#    # To re-enable it's recommended to enable access to the files
#    # only in specific virtual host or directory
#    Require all denied
#</FilesMatch>
# Deny access to files without filename (e.g. '.php')
#<FilesMatch "^\.ph(p[345]?|t|tml|ps)$">
#    Require all denied
#</FilesMatch>
#
# Running PHP scripts in user directories is disabled by default
#
# To re-enable PHP in user directories comment the following lines
# (from <IfModule ...> to </IfModule>.) Do NOT set it to On as it
# prevents .htaccess files from disabling it.
#<IfModule mod_userdir.c>
#    <Directory /home/*/public_html>
#        php_admin_flag engine Off
#    </Directory>
#</IfModule>"
