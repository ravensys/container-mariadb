#!/bin/bash

# |  USER  |  PASS  |  DB  |  ADMIN  |  VALID  |
# | :----- | :----- | :--- | :------ | :------ |
# |  -     |  -     |  -   |  -      |  -      |
# |  -     |  -     |  -   |  +      |  +      |
# |  -     |  -     |  +   |  -      |  -      |
# |  -     |  -     |  +   |  +      |  +      |
# |  -     |  +     |  -   |  -      |  -      |
# |  -     |  +     |  -   |  +      |  -      |
# |  -     |  +     |  +   |  -      |  -      |
# |  -     |  +     |  +   |  +      |  -      |
# |  +     |  -     |  -   |  -      |  -      |
# |  +     |  -     |  -   |  +      |  -      |
# |  +     |  -     |  +   |  -      |  -      |
# |  +     |  -     |  +   |  +      |  -      |
# |  +     |  +     |  -   |  -      |  -      |
# |  +     |  +     |  -   |  +      |  +      |
# |  +     |  +     |  +   |  -      |  +      |
# |  +     |  +     |  +   |  +      |  +      |

function ci_case_entrypoint_validations() {
    local -r TEST_CASE=entrypoint_validations

    echo " ---> Testing invalid environment variable combinations"

    echo " ------> No environment variable set"
    ci_assert_container_fails

    echo " ------> Set environment variables: MARIADB_DATABASE"
    ci_assert_container_fails \
        -e MARIADB_DATABASE=db

    echo " ------> Set environment variables: MARIADB_PASSWORD"
    ci_assert_container_fails \
        -e MARIADB_PASSWORD=pass

    echo " ------> Set environment variables: MARIADB_PASSWORD, MARIADB_ADMIN_PASSWORD"
    ci_assert_container_fails \
        -e MARIADB_PASSWORD=pass \
        -e MARIADB_ADMIN_PASSWORD=adminpass

    echo " ------> Set environment variables: MARIADB_PASSWORD, MARIADB_DATABASE"
    ci_assert_container_fails \
        -e MARIADB_PASSWORD=pass \
        -e MARIADB_DATABASE=db

    echo " ------> Set environment variables: MARIADB_PASSWORD, MARIADB_DATABASE, MARIADB_ADMIN_PASSWORD"
    ci_assert_container_fails \
        -e MARIADB_PASSWORD=pass \
        -e MARIADB_DATABASE=db \
        -e MARIADB_ADMIN_PASSWORD=adminpass

    echo " ------> Set environment variables: MARIADB_USER"
    ci_assert_container_fails \
        -e MARIADB_USER=user

    echo " ------> Set environment variables: MARIADB_USER, MARIADB_ADMIN_PASSWORD"
    ci_assert_container_fails \
        -e MARIADB_USER=user \
        -e MARIADB_ADMIN_PASSWORD=adminpass

    echo " ------> Set environment variables: MARIADB_USER, MARIADB_DATABASE"
    ci_assert_container_fails \
        -e MARIADB_USER=user \
        -e MARIADB_DATABASE=db

    echo " ------> Set environment variables: MARIADB_USER, MARIADB_DATABASE, MARIADB_ADMIN_PASSWORD"
    ci_assert_container_fails \
        -e MARIADB_USER=user \
        -e MARIADB_DATABASE=db \
        -e MARIADB_ADMIN_PASSWORD=adminpass

    echo " ------> Set environment variables: MARIADB_USER, MARIADB_PASSWORD"
    ci_assert_container_fails \
        -e MARIADB_USER=user \
        -e MARIADB_PASSWORD=pass

    echo " ------> Set environment variables: MARIADB_USER(root), MARIADB_PASSWORD, MARIADB_DATABASE, MARIADB_ADMIN_PASSWORD"
    ci_assert_container_fails \
        -e MARIADB_USER=root \
        -e MARIADB_PASSWORD=pass \
        -e MARIADB_DATABASE=db \
        -e MARIADB_ADMIN_PASSWORD=adminpass


    echo " ---> Testing invalid environment variable values"
    local VERY_LONG_IDENTIFIER="very_long_identifier_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

    echo " ------> [ MARIADB_USER ] Invalid character"
    ci_assert_container_fails \
        -e MARIADB_USER=\$invalid \
        -e MARIADB_PASSWORD=pass \
        -e MARIADB_DATABASE=db \
        -e MARIADB_ADMIN_PASSWORD=adminpass

    echo " ------> [ MARIADB_USER ] Too long"
    ci_assert_container_fails \
        -e MARIADB_USER=very_long_user_xx \
        -e MARIADB_PASSWORD=pass \
        -e MARIADB_DATABASE=db \
        -e MARIADB_ADMIN_PASSWORD=adminpass

    echo " ------> [ MARIADB_PASSWORD ] Invalid character"
    ci_assert_container_fails \
        -e MARIADB_USER=user \
        -e MARIADB_PASSWORD="\"" \
        -e MARIADB_DATABASE=db \
        -e MARIADB_ADMIN_PASSWORD=adminpass

    echo " ------> [ MARIADB_DATABASE ] Invalid character"
    ci_assert_container_fails \
        -e MARIADB_USER=user \
        -e MARIADB_PASSWORD=pass \
        -e MARIADB_DATABASE=\$invalid \
        -e MARIADB_ADMIN_PASSWORD=adminpass

    echo " ------> [ MARIADB_DATABASE ] Too long"
    ci_assert_container_fails \
        -e MARIADB_USER=user \
        -e MARIADB_PASSWORD=pass \
        -e MARIADB_DATABASE="${VERY_LONG_IDENTIFIER}" \
        -e MARIADB_ADMIN_PASSWORD=adminpass

    echo " ------> [ MARIADB_ADMIN_PASSWORD ] Invalid character"
    ci_assert_container_fails \
        -e MARIADB_USER=user \
        -e MARIADB_PASSWORD=pass \
        -e MARIADB_DATABASE=db \
        -e MARIADB_ADMIN_PASSWORD="\""
}

function ci_case_entrypoint_validations_desc() {
    echo "container entrypoint validations tests"
}
