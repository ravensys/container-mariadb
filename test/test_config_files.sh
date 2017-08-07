#!/bin/bash

function ci_case_config_files() {
    local -r TEST_CASE=config_file

    echo " ---> Testing non-default values for configuration options"
    MARIADB_FT_MAX_WORD_LEN=10
    MARIADB_FT_MIN_WORD_LEN=2
    MARIADB_INNODB_BUFFER_POOL_SIZE=64M
    MARIADB_INNODB_LOG_BUFFER_SIZE=8M
    MARIADB_INNODB_LOG_FILE_SIZE=16M
    MARIADB_INNODB_USE_NATIVE_AIO=0
    MARIADB_KEY_BUFFER_SIZE=4M
    MARIADB_LOWER_CASE_TABLE_NAMES=1
    MARIADB_MAX_ALLOWED_PACKET=8M
    MARIADB_MAX_CONNECTIONS=222
    MARIADB_READ_BUFFER_SIZE=256K
    MARIADB_SORT_BUFFER_SIZE=512K
    MARIADB_TABLE_OPEN_CACHE=1111

    ci_mariadb_container "${TEST_CASE}_nondefault" testuser testpass \
        -e MARIADB_USER=testuser \
        -e MARIADB_PASSWORD=testpass \
        -e MARIADB_DATABASE=testdb \
        -e MARIADB_FT_MAX_WORD_LEN="${MARIADB_FT_MAX_WORD_LEN}" \
        -e MARIADB_FT_MIN_WORD_LEN="${MARIADB_FT_MIN_WORD_LEN}" \
        -e MARIADB_INNODB_BUFFER_POOL_SIZE="${MARIADB_INNODB_BUFFER_POOL_SIZE}" \
        -e MARIADB_INNODB_LOG_BUFFER_SIZE="${MARIADB_INNODB_LOG_BUFFER_SIZE}" \
        -e MARIADB_INNODB_LOG_FILE_SIZE="${MARIADB_INNODB_LOG_FILE_SIZE}" \
        -e MARIADB_INNODB_USE_NATIVE_AIO="${MARIADB_INNODB_USE_NATIVE_AIO}" \
        -e MARIADB_KEY_BUFFER_SIZE="${MARIADB_KEY_BUFFER_SIZE}" \
        -e MARIADB_LOWER_CASE_TABLE_NAMES="${MARIADB_LOWER_CASE_TABLE_NAMES}" \
        -e MARIADB_MAX_ALLOWED_PACKET="${MARIADB_MAX_ALLOWED_PACKET}" \
        -e MARIADB_MAX_CONNECTIONS="${MARIADB_MAX_CONNECTIONS}" \
        -e MARIADB_READ_BUFFER_SIZE="${MARIADB_READ_BUFFER_SIZE}" \
        -e MARIADB_SORT_BUFFER_SIZE="${MARIADB_SORT_BUFFER_SIZE}" \
        -e MARIADB_TABLE_OPEN_CACHE="${MARIADB_TABLE_OPEN_CACHE}"

    echo " ------> Testing MariaDB configuration"
    ci_assert_configuration "${TEST_CASE}_nondefault"


    echo " ---> Testing configuration auto-tuning capabilities"
    ci_mariadb_config_defaults
    MARIADB_INNODB_BUFFER_POOL_SIZE=384M
    MARIADB_INNODB_LOG_BUFFER_SIZE=96M
    MARIADB_INNODB_LOG_FILE_SIZE=96M
    MARIADB_KEY_BUFFER_SIZE=76M
    MARIADB_READ_BUFFER_SIZE=38M

    ci_mariadb_container "${TEST_CASE}_autotune" testuser testpass \
        -e MARIADB_USER=testuser \
        -e MARIADB_PASSWORD=testpass \
        -e MARIADB_DATABASE=testdb \
        -m 768M

    echo " ------> Testing MariaDB configuration"
    ci_assert_configuration "${TEST_CASE}_autotune"
}

function ci_case_config_files_desc() {
    echo "container MariaDB configuration files tests"
}
