#!/bin/sh
set -eu

set -a
. /bin/nc/lib.sh
set +a

installed_version="0.0.0.0"
if [ -f /var/www/html/config/config.php ]; then
    installed_version="$(php -r 'require "/var/www/html/config/config.php"; echo array_key_exists("version", $CONFIG) ? $CONFIG["version"] : "0.0.0.0";')"
fi
image_version="$(php -r 'require "/var/www/html/version.php"; echo implode(".", $OC_Version);')"

# Install
if [ "$installed_version" = "0.0.0.0" ]; then
    echo "New nextcloud instance"
    echo "Next step: Access your instance to finish the web-based installation."

# Upgrade
elif [ "$installed_version" != "$image_version" ]; then
    echo "Can't start Nextcloud because the version of the data ($installed_version) is different from the docker image version ($image_version)."
    echo 'Please, run init script or upgrade this instance manually.'
    echo 'Waiting 5 minutes'
    sleep 300
    exit 1
fi

exec apache2-foreground
