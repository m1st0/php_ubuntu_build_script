#! /bin/bash
## PHP 7 Initial Compile ##

## Setup Ubuntu 15.04 ##
# I like the speed of Apt-Fast.  Will check for installs some other day.
sudo apt-get install apt-fast
# Uncomment to get the lastest updates.
# sudo apt-fast update && sudo apt-fast upgrade

# Other dependencies for PHP 7. Add any missing ones from configure script
# complaints, plus some LAMP needs too.
sudo apt-fast install libldap2-dev \
  libldap-2.4-2 \
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
  librecode-dev

# PHP 7 does not recognize these without additional parameters or symlinks for
# Ldap.
sudo ln -sf /usr/lib/x86_64-linux-gnu/libldap.so /usr/lib/libldap.so
sudo ln -sf /usr/lib/x86_64-linux-gnu/liblber.so /usr/lib/liblber.so
sudo ln -sf /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h
# Obtain latest source
git clone https://github.com/php/php-src
cd php-src

# Helped fix configure issues.
./buildconf
# Setup compile options for Kubuntu 15.04.  If failures occur, check dependencies
# and symlink needs above.
./configure --prefix=/usr/local/php7 \
    --with-config-file-path=/etc/php7/apache2 \
    --with-config-file-scan-dir=/etc/php7/apache2/conf.d \
    --enable-mbstring \
    --enable-zip \
    --enable-bcmath \
    --enable-pcntl \
    --enable-ftp \
    --enable-exif \
    --enable-calendar \
    --enable-sysvmsg \
    --enable-sysvsem \
    --enable-sysvshm \
    --enable-wddx \
    --with-curl \
    --with-mcrypt \
    --with-iconv \
    --with-gmp \
    --with-pspell \
    --with-gd \
    --with-jpeg-dir=/usr \
    --with-png-dir=/usr \
    --with-zlib-dir=/usr \
    --with-xpm-dir=/usr \
    --with-freetype-dir=/usr \
    --with-t1lib=/usr \
    --enable-gd-native-ttf \
    --enable-gd-jis-conv \
    --with-openssl \
    --with-pdo-mysql=/usr \
    --with-gettext=/usr \
    --with-zlib=/usr \
    --with-bz2 \
    --with-recode=/usr \
    --with-apxs2=/usr/bin/apxs \
    --with-mysqli=/usr/bin/mysql_config \
    --with-ldap

# Cleanup for previous failures.
sudo make clean

# Using as many threads as possible.  Change as necessary. Will check in future
# for cores.
sudo make -j 10

# Install it accoridng to the configured path.
sudo make install

# It's own make script said to do this, but it didn't do much on my system.
libtool --finish ./libs

# Work on non-threaded version as compiled for now.
sudo a2dismod mpm_worker
sudo a2enmod mpm_prefork
# Since it is built with axps2, it sets things up correctly.
sudo a2enmod php7

# Restart Apache if all went well.
sudo systemctl restart apache2
# View any errors for Apache startup.
printf "Any errors starting Apache2 with PHP7 can be seen with 'sudo journalctl -xe' .\n"

# Update the paths on th system according to Ubuntu.  Can be later removed and
# switched back.
sudo update-alternatives --install /usr/bin/php php /usr/local/php7/bin/php 50 \
  --slave /usr/share/man/man1/php.1.gz php.1.gz \
  /usr/local/php7/php/man/man1/php.1

# Choose your PHP version.
printf "Select the version of PHP you want active in subsequent shells and the \
  system:\n"
sudo update-alternatives --config php

## To help enable Apache 2.4 use of PHP 7. Enable this after writing the file.
## /etc/apache2/mods-available/php7.conf
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
