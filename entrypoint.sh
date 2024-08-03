#!/bin/bash


# exec (crontab -l; echo "* * * * * cd /var/www/html;/usr/local/bin/php bin/grav scheduler 1>> /dev/null 2>&1") | crontab -

# remove old vendors folder and copy new one
rm -rf /var/www/vendor
mv /opt/workspace/vendor /var/www/vendor
mv /opt/workspace/composer.lock /var/www/composer.lock

sh -c cron && apache2-foreground