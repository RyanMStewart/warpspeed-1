#!/bin/bash

# Make sure warpspeed environment vars are available before proceeding.
if [ -z "$WARPSPEED_ROOT" ] || [ -z "$WARPSPEED_USER" ]; then
    echo "Error: It appears that this server was not provisioned with Warpspeed."
    echo "WARPSPEED_ROOT and WARPSPEED_USER env vars were not found."
    exit 1
fi

# Import the warpspeed functions.
source $WARPSPEED_ROOT/includes/installer-functions.sh

# Require that the root user be executing this script.
ws_require_root

ws_log_header "Installing php."

apt-get -y install php5 php5-cli php5-pgsql php5-mysql php5-mongo php5-curl php5-mcrypt php5-gd php5-imagick php5-fpm php5-memcached php5-xdebug php5-dev php5-json

# Remove the default php-fpm pool.
mv -f /etc/php5/fpm/pool.d/www.conf /etc/php5/fpm/pool.d/www.conf.orig

# Create directory for logging.
mkdir -p /var/log/php
chown -R $WARPSPEED_USER:www-data /var/log/php

# Create directory for uploads and sessions.
mkdir -p /var/lib/php
chown -R $WARPSPEED_USER:www-data /var/lib/php

# Backup original and then modify php ini settings for fpm.
PHPINI=/etc/php5/fpm/php.ini
cp $PHPINI $PHPINI.orig
sed -i 's/^display_errors = On/display_errors = Off/' $PHPINI
sed -i 's/^expose_php = On/expose_php = Off/' $PHPINI
sed -i 's/^;date.timezone =.*/date.timezone = UTC/' $PHPINI
sed -i 's/^;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' $PHPINI

# Backup original and then modify php ini settings for cli.
PHPINI=/etc/php5/cli/php.ini
cp $PHPINI $PHPINI.orig
sed -i 's/^;date.timezone =.*/date.timezone = UTC/' $PHPINI
sed -i 's@;error_log =.*@error_log = /var/log/php/error-cli.log@' $PHPINI

# Ensure that mcrypt is enabled.
php5enmod mcrypt

# Download and install composer globally.
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Stop the service, remove startup files, and add modified checkconf.
service php5-fpm stop
rm /etc/init.d/php5-fpm
rm /etc/init/php5-fpm.conf
