#!/bin/bash

function _ci_case_secrets_general_helper() {
    local container="$1"; shift
    local secrets_prefix="${1:-mariadb/}"
    local secrets_volume; secrets_volume="$( ci_volume_create "${container}_secrets" )"
    local docker_args="$( ci_mariadb_build_secrets "${secrets_volume}" )"

    if [ -n "${TEST_USER:-}" ] && [ -n "${TEST_PASSWORD:-}" ]; then
        ci_mariadb_container "${container}" "${TEST_USER}" "${TEST_PASSWORD}" ${docker_args}
    elif [ -n "${TEST_ADMIN_PASSWORD:-}" ]; then
        ci_mariadb_container "${container}" root "${TEST_ADMIN_PASSWORD}" ${docker_args}
    else
        exit 1
    fi

    if [ -n "${TEST_USER:-}" ] && [ -n "${TEST_PASSWORD:-}" ]; then
        echo " ------> Testing connection to container as unpriviliged user"
        ci_assert_login_access "${container}" "${TEST_USER}" "${TEST_PASSWORD}" true
        ci_assert_login_access "${container}" "${TEST_USER}" "${TEST_PASSWORD}_invalid" false
    fi

    echo " ------> Testing connection to container as admin"
    if [ -n "${TEST_ADMIN_PASSWORD:-}" ]; then
        ci_assert_login_access "${container}" root "${TEST_ADMIN_PASSWORD}" true
        ci_assert_login_access "${container}" root "${TEST_ADMIN_PASSWORD}_invalid" false
    else
        ci_assert_login_access "${container}" root "" false
        ci_assert_login_access "${container}" root "invalid" false
    fi

    echo " ------> Testing connection to container as local user"
    ci_assert_local_access "${container}"

    echo " ------> Testing MariaDB configuration"
    ci_assert_configuration "${container}"

    if [ -n "${TEST_USER:-}" ] && [ -n "${TEST_PASSWORD:-}" ]; then
        echo " ------> Testing MariaDB queries as unprivileged user"
        ci_assert_mariadb "${container}" "${TEST_USER}" "${TEST_PASSWORD}"
    fi

    if [ -n "${TEST_ADMIN_PASSWORD:-}" ]; then
        echo " ------> Testing MariaDB queries as admin"
        ci_assert_mariadb "${container}" root "${TEST_ADMIN_PASSWORD}"
    fi
}

function ci_case_secrets_general() {
    local -r TEST_CASE=secrets_general

    ci_mariadb_config_defaults

    echo " ---> Testing MariaDB with unprivileged account"
    TEST_USER=testuser \
    TEST_PASSWORD=testpass \
        _ci_case_secrets_general_helper "${TEST_CASE}_user_only"

    echo " ---> Testing MariaDB with unprivileged and admin accounts"
    TEST_USER=testuser \
    TEST_PASSWORD=testpass \
    TEST_ADMIN_PASSWORD=adminpass \
        _ci_case_secrets_general_helper "${TEST_CASE}_user_and_admin" alternative/mariadb/path_

    echo " ---> Testing MariaDB with admin account"
    TEST_ADMIN_PASSWORD=adminpass \
        _ci_case_secrets_general_helper "${TEST_CASE}_admin_only"

    echo " ---> Testing MariaDB with admin account (set as unprivileged account)"
    TEST_USER=root \
    TEST_PASSWORD=adminpass \
        _ci_case_secrets_general_helper "${TEST_CASE}_admin_only_alt"
}

function ci_case_secrets_general_desc() {
    echo "general functionality tests with secrets"
}
