#!/bin/bash

function ci_case_password_change() {
    local -r TEST_CASE=password_change

    echo " ---> Creating MariaDB data volume"
    local mydata_volume; mydata_volume="$( ci_volume_create "${TEST_CASE}_mydata" )"

    echo " ---> Creating initial container"
    ci_mariadb_container "${TEST_CASE}_initial" testuser foo \
        -e MARIADB_USER=testuser \
        -e MARIADB_PASSWORD=foo \
        -e MARIADB_DATABASE=testdb \
        -e MARIADB_ADMIN_PASSWORD=fooadmin \
        -v "${mydata_volume}:/var/lib/mysql/data:Z"

    echo " ------> Testing connection to container as admin"
    ci_assert_login_access "${TEST_CASE}_initial" root fooadmin true

    echo " ------> Stopping initial container [ ${TEST_CASE}_initial ]"
    ci_container_stop "${TEST_CASE}_initial"


    echo " ---> Creating container with updated passwords"
    ci_mariadb_container "${TEST_CASE}_updated" testuser bar \
        -e MARIADB_USER=testuser \
        -e MARIADB_PASSWORD=bar \
        -e MARIADB_DATABASE=testdb \
        -e MARIADB_ADMIN_PASSWORD=baradmin \
        -v "${mydata_volume}:/var/lib/mysql/data:Z"

    echo " ------> Testing connection to container as admin (with updated credentials)"
    ci_assert_login_access "${TEST_CASE}_updated" root baradmin true

    echo " ------> Testing connection to container as unprivileged user (with initial credentials)"
    ci_assert_login_access "${TEST_CASE}_updated" testuser foo false

    echo " ------> Testing connection to container as admin (with initial credentials)"
    ci_assert_login_access "${TEST_CASE}_updated" root fooadmin false
}

function ci_case_password_change_desc() {
    echo "MariaDB accounts password change tests"
}
