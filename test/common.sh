#!/bin/bash

[ -n "${TESTDIR:-}" ] || \
    ( echo "Test suite source directory is not set!" && exit 1 )
[ -n "${COMMONDIR:-}" ] || \
    ( echo "Common tests source directory is not set!" && exit 1 )

function ci_volume_set_permissions() {
    local volume_dir="$1"; shift

    setfacl -m u:27:rwx "${volume_dir}"
}

function ci_mariadb_build_envs() {
    local docker_args

    if [ -n "${TEST_ADMIN_PASSWORD:-}" ]; then
        docker_args+=" -e MARIADB_ADMIN_PASSWORD=${TEST_ADMIN_PASSWORD}"
    fi

    if [ -n "${TEST_USER:-}" ]; then
        docker_args+=" -e MARIADB_USER=${TEST_USER}"
    fi

    if [ -n "${TEST_PASSWORD:-}" ]; then
        docker_args+=" -e MARIADB_PASSWORD=${TEST_PASSWORD}"
    fi

    docker_args+=" -e MARIADB_DATABASE=testdb"

    echo "${docker_args}"
}

function ci_mariadb_build_secrets() {
    local secrets_volume="$1"; shift
    local secrets_prefix="${1:-mariadb/}"
    local docker_args=" -v ${secrets_volume}:/run/secrets"

    if [ -n "${TEST_ADMIN_PASSWORD:-}" ]; then
        ci_secret_create "${secrets_volume}" "${secrets_prefix}admin_password" "${TEST_ADMIN_PASSWORD}"
        [ "mariadb/" == "${secrets_prefix}" ] || \
            docker_args+=" -e MARIADB_ADMIN_PASSWORD_SECRET=${secrets_prefix}admin_password"
    fi

    if [ -n "${TEST_USER:-}" ]; then
        ci_secret_create "${secrets_volume}" "${secrets_prefix}user" "${TEST_USER}"
        [ "mariadb/" == "${secrets_prefix}" ] || \
            docker_args+=" -e MARIADB_USER_SECRET=${secrets_prefix}user"
    fi

    if [ -n "${TEST_PASSWORD:-}" ]; then
        ci_secret_create "${secrets_volume}" "${secrets_prefix}password" "${TEST_PASSWORD}"
        [ "mariadb/" == "${secrets_prefix}" ] || \
            docker_args+=" -e MARIADB_PASSWORD_SECRET=${secrets_prefix}password"
    fi

    ci_secret_create "${secrets_volume}" "${secrets_prefix}database" testdb
    [ "mariadb/" == "${secrets_prefix}" ] || \
        docker_args+=" -e MARIADB_DATABASE_SECRET=${secrets_prefix}database"

    echo "${docker_args}"
}

function ci_mariadb_cmd() {
    local ip="$1"; shift
    local user="$1"; shift
    local password="$1"; shift

    docker run --rm "${IMAGE_NAME}" \
        mysql --host "${ip}" -u"${user}" -p"${password}" "$@" testdb
}

function ci_mariadb_config_defaults() {
    MARIADB_FT_MAX_WORD_LEN=20
    MARIADB_FT_MIN_WORD_LEN=4
    MARIADB_INNODB_BUFFER_POOL_SIZE=128M
    MARIADB_INNODB_LOG_BUFFER_SIZE=16M
    MARIADB_INNODB_LOG_FILE_SIZE=48M
    MARIADB_INNODB_USE_NATIVE_AIO=1
    MARIADB_KEY_BUFFER_SIZE=8M
    MARIADB_LOWER_CASE_TABLE_NAMES=0
    MARIADB_MAX_ALLOWED_PACKET=4M
    MARIADB_MAX_CONNECTIONS=151
    MARIADB_READ_BUFFER_SIZE=128K
    MARIADB_SORT_BUFFER_SIZE=256K
    MARIADB_TABLE_OPEN_CACHE=2000
}

function ci_mariadb_container() {
    local container="$1"; shift
    local user="$1"; shift
    local password="$1"; shift

    echo " ------> Creating MariaDB container [ ${container} ]"
    ci_container_create "${container}" "$@"

    echo " ------> Verifying initial connection to container as ${user}(${password})"
    ci_mariadb_wait_connection "${container}" "${user}" "${password}"
}

function ci_mariadb_wait_connection() {
    local container="$1"; shift
    local user="$1"; shift
    local password="$1"; shift
    local max_attempts="${1:-20}"

    local i
    local container_ip; container_ip="$( ci_container_get_ip "${container}" )"
    for i in $( seq ${max_attempts} ); do
        echo " ------> Connection attempt to container [ ${container} ] < ${i} / ${max_attempts} >"
        if ci_mariadb_cmd "${container_ip}" "${user}" "${password}" <<< "SELECT 1;"; then
            return
        fi
        sleep 2
    done

    exit 1
}

function ci_assert_config_option() {
    local container="$1"; shift
    local option_name="$1"; shift
    local option_value="$1"; shift

    docker exec $( ci_container_get_cid "${container}" ) \
        bash -c "grep -qx '${option_name} = ${option_value}' /etc/my.cnf.d/*.cnf"
}

function ci_assert_configuration() {
    local container="$1"; shift

    ci_assert_config_option "${container}" ft_max_word_len "${MARIADB_FT_MAX_WORD_LEN}"
    ci_assert_config_option "${container}" ft_min_word_len "${MARIADB_FT_MIN_WORD_LEN}"
    ci_assert_config_option "${container}" innodb_buffer_pool_size "${MARIADB_INNODB_BUFFER_POOL_SIZE}"
    ci_assert_config_option "${container}" innodb_log_buffer_size "${MARIADB_INNODB_LOG_BUFFER_SIZE}"
    ci_assert_config_option "${container}" innodb_log_file_size "${MARIADB_INNODB_LOG_FILE_SIZE}"
    ci_assert_config_option "${container}" innodb_use_native_aio "${MARIADB_INNODB_USE_NATIVE_AIO}"
    ci_assert_config_option "${container}" key_buffer_size "${MARIADB_KEY_BUFFER_SIZE}"
    ci_assert_config_option "${container}" lower_case_table_names "${MARIADB_LOWER_CASE_TABLE_NAMES}"
    ci_assert_config_option "${container}" max_allowed_packet "${MARIADB_MAX_ALLOWED_PACKET}"
    ci_assert_config_option "${container}" max_connections "${MARIADB_MAX_CONNECTIONS}"
    ci_assert_config_option "${container}" read_buffer_size "${MARIADB_READ_BUFFER_SIZE}"
    ci_assert_config_option "${container}" sort_buffer_size "${MARIADB_SORT_BUFFER_SIZE}"
    ci_assert_config_option "${container}" table_open_cache "${MARIADB_TABLE_OPEN_CACHE}"
}

function ci_assert_container_fails() {
    local ret=0
    timeout -s 9 --preserve-status 60s docker run --rm "$@" "${IMAGE_NAME}" || ret=$?

    [ ${ret} -lt 100 ] || \
        exit 1
}

function ci_assert_local_access() {
    local container="$1"; shift

    docker exec $( ci_container_get_cid "${container}" ) \
        bash -c 'mysql -uroot <<< "SELECT 1;"'
}

function ci_assert_login_access() {
    local container="$1"; shift
    local user="$1"; shift
    local password="$1"; shift
    local success="$1"; shift

    if ci_mariadb_cmd $( ci_container_get_ip "${container}" ) "${user}" "${password}" <<< "SELECT 1;"; then
        if $success; then
            echo "${user}(${password}) access granted as expected."
            return
        fi
    else
        if ! $success; then
            echo "${user}(${password}) access denied as expected."
            return
        fi
    fi

    echo "${user}(${password}) login assertion failed."
    exit 1
}

function ci_assert_mariadb() {
    local container="$1"; shift
    local user="$1"; shift
    local password="$1"; shift

    local container_ip; container_ip="$( ci_container_get_ip "${container}" )"
    ci_mariadb_cmd "${container_ip}" "${user}" "${password}" <<< "CREATE TABLE testtbl (testcol1 VARCHAR(20), testcol2 VARCHAR(20));"
    ci_mariadb_cmd "${container_ip}" "${user}" "${password}" <<< "INSERT INTO testtbl VALUES('foo1', 'bar1');"
    ci_mariadb_cmd "${container_ip}" "${user}" "${password}" <<< "INSERT INTO testtbl VALUES('foo2', 'bar2');"
    ci_mariadb_cmd "${container_ip}" "${user}" "${password}" <<< "SELECT * FROM testtbl;"
    ci_mariadb_cmd "${container_ip}" "${user}" "${password}" <<< "DROP TABLE testtbl;"
}
