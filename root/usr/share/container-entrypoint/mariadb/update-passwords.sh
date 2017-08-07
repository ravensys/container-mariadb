#!/bin/bash

function mariadb_update_passwords() {
    local mariadb_user; mariadb_user="$( get_value MARIADB_USER '' )"
    local mariadb_password; mariadb_password="$( get_value MARIADB_PASSWORD '' )"
    if [ -n "${mariadb_password}" ]; then
        mariadb_set_password "${mariadb_user}" "${mariadb_password}"
    fi

    local mariadb_admin_password; mariadb_admin_password="$( get_value MARIADB_ADMIN_PASSWORD '' )"
    if [ -n "${mariadb_admin_password}" ]; then
        if version_ge "${MARIADB_VERSION}"  "10.1"; then
            mariadb_create_user_if_not_exists root
        fi
        mariadb_cmd <<EOSQL
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '${mariadb_admin_password}' WITH GRANT OPTION;
EOSQL
    elif [ "root" != "${mariadb_user}" ]; then
        mariadb_drop_user root
    fi
}

mariadb_update_passwords
