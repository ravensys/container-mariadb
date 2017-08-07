#!/bin/bash

export MARIADB_CONFIG="/etc/my.cnf"
export MARIADB_DATADIR="/var/lib/mysql/data/mariadata"
export MARIADB_SOCKET="$( mktemp --tmpdir mariadb_XXXXXX.sock )"

readonly MARIADB_IDENTIFIER_REGEX='^[a-zA-Z0-9_]+$'
readonly MARIADB_PASSWORD_REGEX='^[a-zA-Z0-9_~!@#$%^&*()-=<>,.?;:|]+$'

function get_secret_mapping() {
    local variable="$1"; shift

    case "${variable}" in
        "MARIADB_ADMIN_PASSWORD" )
            echo mariadb/admin_password ;;
        "MARIADB_DATABASE" )
            echo mariadb/database ;;
        "MARIADB_PASSWORD" )
            echo mariadb/password ;;
        "MARIADB_USER" )
            echo mariadb/user ;;
        * )
            echo "${variable}" ;;
    esac
}

function mariadb_cleanup_environment() {
    unset MARIADB_ADMIN_PASSWORD \
          MARIADB_DATABASE \
          MARIADB_PASSWORD \
          MARIADB_USER
}

function mariadb_cmd() {
    mysql --socket="${MARIADB_SOCKET}" --user=root "$@"
}

function mariadb_create_database() {
    local database="$1"; shift

    mariadb_cmd <<EOSQL
CREATE DATABASE \`${database}\`;
EOSQL
}

function mariadb_create_database_if_not_exists() {
    local database="$1"; shift

    mariadb_cmd <<EOSQL
CREATE DATABASE IF NOT EXISTS \`${database}\`;
EOSQL
}

function mariadb_create_user() {
    local user="$1"; shift

    mariadb_cmd <<EOSQL
CREATE USER '${user}'@'%';
FLUSH PRIVILEGES;
EOSQL
}

function mariadb_create_user_if_not_exists() {
    local user="$1"; shift

    mariadb_cmd <<EOSQL
CREATE USER IF NOT EXISTS '${user}'@'%';
FLUSH PRIVILEGES;
EOSQL
}

function mariadb_drop_database() {
    local database="$1"; shift

    mariadb_cmd <<EOSQL
DROP DATABASE IF EXISTS \`${database}\`;
EOSQL
}

function mariadb_drop_user() {
    local user="$1"; shift

    if version_lt "${MARIADB_VERSION}" "10.1"; then
        mariadb_cmd <<EOSQL
GRANT USAGE ON *.* TO '${user}'@'%';
DROP USER '${user}'@'%';
FLUSH PRIVILEGES;
EOSQL
    else
        mariadb_cmd <<EOSQL
DROP USER IF EXISTS '${user}'@'%';
FLUSH PRIVILEGES;
EOSQL
    fi
}

function mariadb_export_config_variables() {
    export MARIADB_FT_MAX_WORD_LEN="${MARIADB_FT_MAX_WORD_LEN:-20}"
    export MARIADB_FT_MIN_WORD_LEN="${MARIADB_FT_MIN_WORD_LEN:-4}"
    export MARIADB_INNODB_USE_NATIVE_AIO="${MARIADB_INNODB_USE_NATIVE_AIO:-1}"
    export MARIADB_LOWER_CASE_TABLE_NAMES="${MARIADB_LOWER_CASE_TABLE_NAMES:-0}"
    export MARIADB_MAX_ALLOWED_PACKET="${MARIADB_MAX_ALLOWED_PACKET:-4M}"
    export MARIADB_MAX_CONNECTIONS="${MARIADB_MAX_CONNECTIONS:-151}"
    export MARIADB_SORT_BUFFER_SIZE="${MARIADB_SORT_BUFFER_SIZE:-256K}"
    export MARIADB_TABLE_OPEN_CACHE="${MARIADB_TABLE_OPEN_CACHE:-2000}"

    local CGROUP_MEMORY_LIMIT_IN_BYTES=$( cgroup_get_memory_limit_in_bytes )

    if [ -n "${CGROUP_MEMORY_LIMIT_IN_BYTES}" ] &&  [ ${CGROUP_MEMORY_LIMIT_IN_BYTES} -gt 0 ]; then
        export MARIADB_INNODB_BUFFER_POOL_SIZE="${MARIADB_INNODB_BUFFER_POOL_SIZE:-$(( CGROUP_MEMORY_LIMIT_IN_BYTES/1024/1024/2 ))M}"
        export MARIADB_INNODB_LOG_BUFFER_SIZE="${MARIADB_INNODB_LOG_BUFFER_SIZE:-$(( CGROUP_MEMORY_LIMIT_IN_BYTES/1024/1024/8 ))M}"
        export MARIADB_INNODB_LOG_FILE_SIZE="${MARIADB_INNODB_LOG_FILE_SIZE:-$(( CGROUP_MEMORY_LIMIT_IN_BYTES/1024/1024/8 ))M}"
        export MARIADB_KEY_BUFFER_SIZE="${MARIADB_KEY_BUFFER_SIZE:-$(( CGROUP_MEMORY_LIMIT_IN_BYTES/1024/1024/10 ))M}"
        export MARIADB_READ_BUFFER_SIZE="${MARIADB_READ_BUFFER_SIZE:-$(( CGROUP_MEMORY_LIMIT_IN_BYTES/1024/1024/20 ))M}"
    else
        export MARIADB_INNODB_BUFFER_POOL_SIZE="${MARIADB_INNODB_BUFFER_POOL_SIZE:-128M}"
        export MARIADB_INNODB_LOG_BUFFER_SIZE="${MARIADB_INNODB_LOG_BUFFER_SIZE:-16M}"
        export MARIADB_INNODB_LOG_FILE_SIZE="${MARIADB_INNODB_LOG_FILE_SIZE:-48M}"
        export MARIADB_KEY_BUFFER_SIZE="${MARIADB_KEY_BUFFER_SIZE:-8M}"
        export MARIADB_READ_BUFFER_SIZE="${MARIADB_READ_BUFFER_SIZE:-128K}"
    fi
}

function mariadb_generate_config() {
    envsubst \
        < "${CONTAINER_ENTRYPOINT_PATH}/mariadb/mariadb-container.cnf.template" \
        > "${MARIADB_CONFIG}.d/mariadb-container.cnf"

    envsubst \
        < "${CONTAINER_ENTRYPOINT_PATH}/mariadb/mariadb-container-tuning.cnf.template" \
        > "${MARIADB_CONFIG}.d/mariadb-container-tuning.cnf"
}

function mariadb_grant_privileges() {
    local database="$1"; shift
    local user="$1"; shift

    mariadb_cmd <<EOSQL
GRANT ALL ON \`${database}\`.* TO '${user}'@'%';
FLUSH PRIVILEGES;
EOSQL
}

function mariadb_initialize() {
    mysql_install_db --datadir="${MARIADB_DATADIR}" --rpm

    mariadb_start_local

    local mariadb_user; mariadb_user="$( get_value MARIADB_USER '' )"
    if [ -n "${mariadb_user}" ]; then
        log_message " ---> Creating user \`${mariadb_user}\`"
        mariadb_create_user "${mariadb_user}"
    fi

    local mariadb_database; mariadb_database="$( get_value MARIADB_DATABASE '' )"
    if [ -n "${mariadb_database}" ]; then
        log_message " ---> Creating database \`${mariadb_database}\`"
        mariadb_create_database "${mariadb_database}"

        if [ -n "${mariadb_user}" ]; then
            echo " ---> Granting privileges on \`${mariadb_database}\` to \`${mariadb_user}\`"
            mariadb_grant_privileges "${mariadb_database}" "${mariadb_user}"
        fi
    fi
}

function mariadb_is_initialized() {
    [ -d "${MARIADB_DATADIR}/mysql" ]
}

function mariadb_set_password() {
    local user="$1"; shift
    local password="$1"; shift

    mariadb_cmd <<EOSQL
SET PASSWORD FOR '${user}'@'%' = PASSWORD('${password}');
EOSQL
}

function mariadb_start_local() {
    mysqld --datadir="${MARIADB_DATADIR}" --skip-networking --socket="${MARIADB_SOCKET}" &

    local mariadb_pid=$!
    mariadb_wait_for_start "${mariadb_pid}"
}

function mariadb_stop_local() {
    mysqladmin --socket="${MARIADB_SOCKET}" --user=root flush-privileges shutdown
    rm -f "${MARIADB_SOCKET}"
}

function mariadb_wait_for_start() {
    local pid="$1" ; shift

    while true; do
        if [ ! -d "/proc/${pid}" ]; then
            exit 1
        fi

        mysqladmin --socket="${MARIADB_SOCKET}" --user=root ping &>/dev/null && return
        log_message " ---> Waiting for MariaDB server to start ..."
        sleep 2
    done
}
