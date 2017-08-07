#!/bin/bash

function ci_case_secrets_priority() {
    local -r TEST_CASE=secrets_priority

    echo " ------> Creating docker secrets volume"
    local secrets_volume; secrets_volume="$( ci_volume_create "${TEST_CASE}_secrets" )"

    echo " ------> Creating docker secrets (simulation)"
    ci_secret_create "${secrets_volume}" mariadb/user secretuser
    ci_secret_create "${secrets_volume}" mariadb/password secretpass
    ci_secret_create "${secrets_volume}" mariadb/database testdb

    ci_mariadb_container "${TEST_CASE}" secretuser secretpass \
        -e MARIADB_USER=testuser \
        -e MARIADB_PASSWORD=testpass \
        -e MARIADB_DATABASE=testdb \
        -v "${secrets_volume}:/run/secrets:Z"

    echo " -------> Testing connection to container (with credentials set in environment variables)"
    ci_assert_login_access "${TEST_CASE}" testuser testpass false
}

function ci_case_secrets_priority_desc() {
    echo "docker secrets priority (over environment variables) tests"
}
