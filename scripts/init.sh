#!/bin/sh
set -eu

set -a
. /bin/nc/lib.sh
set +a

uid="$(id -u)"
gid="$(id -g)"
if [ "$uid" = '0' ]; then
    user="${APACHE_RUN_USER:-www-data}"
    group="${APACHE_RUN_GROUP:-www-data}"
    # strip off any '#' symbol ('#1000' is valid syntax for Apache)
    user="${user#'#'}"
    group="${group#'#'}"
else
    user="$uid"
    group="$gid"
fi

installed_version="0.0.0.0"
if [ -f /var/www/html/config/config.php ]; then
    installed_version="$(php -r 'require "/var/www/html/config/config.php"; echo array_key_exists("version", $CONFIG) ? $CONFIG["version"] : "0.0.0.0";')"
fi
image_version="$(php -r 'require "/var/www/html/version.php"; echo implode(".", $OC_Version);')"

if version_greater "$installed_version" "$image_version"; then
    echo "Can't start Nextcloud because the version of the data ($installed_version) is higher than the docker image version ($image_version) and downgrading is not supported."
    echo 'Waiting 5 minutes'
    sleep 300
    exit 1
fi

echo "Initializing nextcloud $image_version ..."

if version_greater "$image_version" "$installed_version"; then

    # Install
    if [ "$installed_version" = "0.0.0.0" ]; then
        echo "New nextcloud instance"
        echo "Next step: Access your instance to finish the web-based installation."

    # Upgrade
    else

        if [ "${image_version%%.*}" -gt "$((${installed_version%%.*} + 1))" ]; then
            echo "Can't start Nextcloud because upgrading from $installed_version to $image_version is not supported."
            echo 'It is only possible to upgrade one major version at a time. For example, if you want to upgrade from version 14 to 16, you will have to upgrade from version 14 to 15, then from 15 to 16.'
            echo 'Waiting 5 minutes'
            sleep 300
            exit 1
        fi

        echo "Upgrading nextcloud from $installed_version ..."
        get_enabled_apps > /tmp/list_before
        run_path pre-upgrade
        run_as 'php /var/www/html/occ upgrade'

        get_enabled_apps > /tmp/list_after
        disabled_apps="$(comm -23 /tmp/list_before /tmp/list_after || true)"
        if [ -n "$disabled_apps" ]; then
            echo "The following apps have been disabled:"
            printf '%s\n' "$disabled_apps"
        fi
        rm -f /tmp/list_before /tmp/list_after

        run_path post-upgrade
    fi
fi

echo "Initialization finished"
