#!/bin/bash

function mariadb_usage() {
    [ $# -eq 1 ] && echo "$1" >&2

    cat >&2 <<EOHELP

MariaDB SQL database server Docker image

Environment variables (container initialization):
  MARIADB_ADMIN_PASSWORD  Password for the admin \`root\` account
  MARIADB_DATABASE        Name of database to be created
  MARIADB_PASSWORD        Password for the user account
  MARIADB_USER            Name of user to be created

Environment variables (mariadb configuration):

  MARIADB_FT_MAX_WORD_LEN
  MARIADB_FT_MIN_WORD_LEN
  MARIADB_INNODB_BUFFER_POOL_SIZE
  MARIADB_INNODB_LOG_BUFFER_SIZE
  MARIADB_INNODB_LOG_FILE_SIZE
  MARIADB_INNODB_USE_NATIVE_AIO
  MARIADB_KEY_BUFFER_SIZE
  MARIADB_LOWER_CASE_TABLE_NAMES
  MARIADB_MAX_ALLOWED_PACKET
  MARIADB_MAX_CONNECTIONS
  MARIADB_READ_BUFFER_SIZE
  MARIADB_SORT_BUFFER_SIZE
  MARIADB_TABLE_OPEN_CACHE

Secrets:
  mariadb/admin_password  Password for the admin \`root\` account
                          (environment variable: MARIADB_ADMIN_PASSWORD_SECRET)
  mariadb/database        Name of database to be created
                          (environment variable: MARIADB_DATABASE_SECRET)
  mariadb/password        Password for the user account
                          (environment variable: MARIADB_PASSWORD_SECRET)
  mariadb/user            Name of user to be created
                          (environment variable: MARIADB_USER_SECRET)

Volumes:
  /var/lib/mysql/data   MariaDB data directory

For more information see /usr/share/container-scripts/mariadb/README.md within container
or visit <https://github.com/ravensys/container-mariadb>.
EOHELP

    exit 1
}

function myql_validate_variables() {
    local user_specified=0
    local root_specified=0

    local mariadb_admin_password; mariadb_admin_password="$( get_value MARIADB_ADMIN_PASSWORD '' )"
    local mariadb_database; mariadb_database="$( get_value MARIADB_DATABASE '' )"
    local mariadb_password; mariadb_password="$( get_value MARIADB_PASSWORD '' )"
    local myql_user; myql_user="$( get_value MARIADB_USER '' )"

    if [ -n "${myql_user}" ] || [ -n "${mariadb_password}" ]; then
        [[ "${myql_user}" =~ ${MARIADB_IDENTIFIER_REGEX} ]] || \
            mariadb_usage "Invalid MariaDB user (invalid character or empty)."

        [ ${#myql_user} -le 16 ] || \
            mariadb_usage "Invalid MariaDB user (too long, max. 16 characters)."

        [[ "${mariadb_password:-}" =~ ${MARIADB_PASSWORD_REGEX} ]] || \
            mariadb_usage "Invalid MariaDB password (invalid character or empty)."

        user_specified=1
    fi

    if [ -n "${mariadb_admin_password}" ]; then
        [[ "${mariadb_admin_password}" =~ ${MARIADB_PASSWORD_REGEX} ]] || \
            mariadb_usage "Invalid MariaDB admin password (invalid character or empty)."

        root_specified=1
    fi

    if [ ${user_specified} -eq 1 ] && [ "root" == "${myql_user}" ]; then
        [ ${root_specified} -eq 0 ] || \
            mariadb_usage "When MARIADB_USER is set to 'root' admin password must be set only in MARIADB_PASSWORD."

        user_specified=0
        root_specified=1
    fi

    [ ${user_specified} -eq 1 ] || [ ${root_specified} -eq 1 ] || \
        mariadb_usage

    [ ${root_specified} -eq 0 ] && [ -z "${mariadb_database}" ] && \
        mariadb_usage

    if [ -n "${mariadb_database}" ]; then
        [[ "${mariadb_database}" =~ ${MARIADB_IDENTIFIER_REGEX} ]] || \
            mariadb_usage "Invalid MariaDB database name (invalid character or empty)."

        [ ${#mariadb_database} -le 64 ] || \
            mariadb_usage "Invalid MariaDB database name (too long, max. 64 characters)."
    fi
}

myql_validate_variables
