MariaDB 5.5 SQL database server Docker image
============================================

This container image includes MariaDB database server version 5.5 based on CentOS.

The CentOS image is available on [Docker Hub](https://hub.docker.com/r/ravensys/mariadb) as
`ravensys/mariadb:5.5-centos7`.


Description
-----------

This container image provides a containerized packaging of the MariaDB mysqld daemon and client application. The mysqld 
server daemon accepts connections from clients and provides access to content from MariaDB databases on behalf of the 
clients. You can find more information on the MariaDB project from the project Web site (https://mariadb.org/).


Usage
-----

If the database data directory is not initialized, the entrypoint script will first run `mysql_install_db` and setup 
necessary database users and password. After database is initialized, or if it was already present, `mysqld` is 
executed and will run as PID 1.

* **Simple user with database**

    This will create a container named `mariadb_database` running MariaDB with database named `db` and user with
    credentials `user:pass`. Port 3306 will be exposed and mapped to host.
    
    ```
    $ docker run -d --name mariadb_database -e MARIADB_USER=user -e MARIADB_PASSWORD=pass -e MARIADB_DATABASE=db -p 3306:3306 ravensys/mariadb:5.5-centos7
    ```

* **Simple user without database**

    This will create a container named `mariadb_database` running MariaDB with user with credentials `user:pass` and admin 
    with credentials `root:rootpass`. Port 3306 will be exposed and mapped to host.
    
    ```
    $ docker run -d --name mariadb_database -e MARIADB_USER=user -e MARIADB_PASSWORD=pass -e MARIADB_ADMIN_PASSWORD=rootpass -p 3306:3306 ravensys/mariadb:5.5-centos7
    ```

* **Only admin account**

    This will create a container named `mariadb_database` running MariaDB with admin with credentials `root:rootpass`. 
    Port 3306 will be exposed and mapped to host.
    
    ```
    $ docker run -d --name mariadb_database -e MARIADB_ADMIN_PASSWORD=rootpass -p 3306:3306 ravensys/mariadb:5.5-centos7
    ```
    
    Alternatively the same configuration can be achieved by setting `MARIADB_USER` environment variable to `root`.
    
    ```
    $ docker run -d --name mariadb_database -e MARIADB_USER=root -e MARIADB_PASSWORD=rootpass -p 3306:3306 ravensys/mariadb:5.5-centos7
    ```

To make database data persistent across container executions add `-v /host/db/path:/var/lib/mysql/data` argument to the
Docker run command.

To stop detached container simply run `docker stop mariadb_database`.


Environment variables
---------------------

The image recognizes following environment variables which can be set during initialization by passing `-e VAR=VALUE`
to the Docker run command.

|  Variable name             |  Description                            |
| :------------------------- | :-------------------------------------- |
|  `MARIADB_ADMIN_PASSWORD`  |  Password for the `root` admin account  |
|  `MARIADB_DATABASE`        |  Name of database to be created         |
|  `MARIADB_PASSWORD`        |  Password for the user account          |
|  `MARIADB_USER`            |  Name of user to be created             |

Following environment variables influence MariaDB configuration file. They are all OPTIONAL.

|  Variable name                      |  Description                                                                                                                                                                                                                                                    |  Default                             |
| :---------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :----------------------------------- |
|  `MARIADB_FT_MAX_WORD_LEN`          |  The maximum length of the word to be included in a MyISAM FULLTEXT index.                                                                                                                                                                                      |  20                                  |
|  `MARIADB_FT_MIN_WORD_LEN`          |  The minimum length of the word to be included in a MyISAM FULLTEXT index.                                                                                                                                                                                      |  4                                   |
|  `MARIADB_INNODB_BUFFER_POOL_SIZE`  |  The size in bytes of the buffer pool, the memory area where InnoDB caches table and index data.                                                                                                                                                                |  128M (or 50% of available memory)   |
|  `MARIADB_INNODB_LOG_BUFFER_SIZE`   |  The size in bytes of the buffer that InnoDB uses to write to the log files on disk.                                                                                                                                                                            |  16M (or 12.5% of available memory)  |
|  `MARIADB_INNODB_LOG_FILE_SIZE`     |  The size in bytes of each log file in a log group.                                                                                                                                                                                                             |  48M (or 12.5% of available memory)  |
|  `MARIADB_INNODB_USE_NATIVE_AIO`    |  Specifies whether to use the Linux asynchronous I/O subsystem.                                                                                                                                                                                                 |  1                                   |
|  `MARIADB_KEY_BUFFER_SIZE`          |  The size of the buffer used for index blocks.                                                                                                                                                                                                                  |  8M (or 10% of available memory)     |
|  `MARIADB_LOWER_CASE_TABLE_NAMES`   |  If set to 0, table names are stored as specified and comparisons are case sensitive. If set to 1, table names are stored in lowercase on disk and comparisons are not case sensitive. If set to 2, table names are stored as given but compared in lowercase.  |  0                                   |
|  `MARIADB_MAX_ALLOWED_PACKET`       |  The maximum size of one packet or any generated/intermediate string.                                                                                                                                                                                           |  4M                                  |
|  `MARIADB_MAX_CONNECTIONS`          |  The maximum permitted number of simultaneous client connections.                                                                                                                                                                                               |  151                                 |
|  `MARIADB_READ_BUFFER_SIZE`         |  The size of buffer used for sequential scan.                                                                                                                                                                                                                   |  128K (or 5% of available memory)    |
|  `MARIADB_SORT_BUFFER_SIZE`         |  The size of buffer used for sorting.                                                                                                                                                                                                                           |  256K                                |
|  `MARIADB_TABLE_OPEN_CACHE`         |  The number of open tables for all threads.                                                                                                                                                                                                                     |  2000                                |


Secrets
-------

The image recognizes following secrets which can be created by running `echo <value> | docker secret create <name>`.

Default secret name can be changed by setting respective environment variable during initialization, value represents 
a relative path to a file located in secrets volume.

|  Secret name               |  Description                            |  Environment variable             |
| :------------------------- | :-------------------------------------- | :-------------------------------- |
|  `mariadb/admin_password`  |  Password for the `root` admin account  |  `MARIADB_ADMIN_PASSWORD_SECRET`  |
|  `mariadb/database`        |  Name of database to be created         |  `MARIADB_DATABASE_SECRET`        |
|  `mariadb/password`        |  Password for the user account          |  `MARIADB_PASSWORD_SECRET`        |
|  `mariadb/user`            |  Name of user to be created             |  `MARIADB_USER_SECRET`            |

**Notice: Secrets takes precedence over environment variables, if both secret and environment variable are set, the 
value from secret is used.**


Volumes
-------

The following mount points can be set by passing `-v /host/path:/container/path` to the Docker run command.

|  Volume mount point     |  Description             |
| :---------------------- | :----------------------- |
|  `/var/lib/mysql/data`  |  MariaDB data directory  |

**Notice: When mounting a directory from host into container, ensure that the mounted directory has appropriate
permissions and that owner and group of directory matches UID of user running inside container.**


MariaDB auto-tuning
-----------------

When MariaDB image is run with the `--memory` parameter set and if there are no values provided for these environment 
variables, their values will be automatically calculated based on available memory.

|  Variable name                      |  Configuration parameter    |  Relative value  |
| :---------------------------------- | :-------------------------- | :--------------- |
|  `MARIADB_INNODB_BUFFER_POOL_SIZE`  |  `innodb_buffer_pool_size`  |  50%             |
|  `MARIADB_INNODB_LOG_BUFFER_SIZE`   |  `innodb_log_buffer_size`   |  12.5%           |
|  `MARIADB_INNODB_LOG_FILE_SIZE`     |  `innodb_log_file_size`     |  12.5%           |
|  `MARIADB_KEY_BUFFER_SIZE`          |  `key_buffer_size`          |  10%             |
|  `MARIADB_READ_BUFFER_SIZE`         |  `read_buffer_size`         |  5%              |


MariaDB admin account
-------------------

The admin account `root` has no password set by default, only allowing local connections. To allow `root` user login 
remotely the `MARIADB_ADMIN_PASSWORD` environment variable must be set when initializing container. Local connections 
will still not require password.


MariaDB unprivileged account
--------------------------

The unprivileged user account with `MARIADB_USER` name is created, authenticated by password set in `MARIADB_PASSWORD`, 
with all privileges to database `MARIADB_DATABASE`.


Changing passwords
------------------

Since passwords are part of the image configuration, the only supported method to change passwords for database user
(`MARIADB_USER`) and admin `root` is by changing environment variables `MARIADB_PASSWORD` and `MARIADB_ADMIN_PASSWORD`,
respectively.

Changing these database passwords through SQL statements or any way other than through environment variables
aforementioned will cause a mismatch between values stored in variables and actual passwords. Whenever a database
container stars it will reset passwords to values stored in environment variables.


Post-initialization scripts
---------------------------

Image initialization process can by extended by placing sourcable shell scripts, these must have a `.sh` extension,
into post-initialization drop-in `/usr/share/container-entrypoint/mariadb/post-init.d` directory.

* **Mount volume with post-init scripts**
 
    To propagate post-initialization scripts from host into container add volume mount
    `-v /path/to/post-init/scripts:/usr/share/container-entrypoint/mariadb/post-init.d` argument to the Docker 
    run command.

    ```
    $ docker run -d --name mariadb_database -v /path/to/post-init/scripts:/usr/share/container-entrypoint/mariadb/post-init.d -e MARIADB_ADMIN_PASSWORD=rootpass -p 3306:3306 ravensys/mariadb:5.5-centos7
    ```

* **Extend image with post-init scripts** 
    
    This Dockerfile will create a Docker image based on `ravensys/mariadb:5.5-centos7` with built-in 
    post-initialization scripts from directory `post-init-scripts`. 
    
    ```dockerfile
    FROM ravensys/mariadb:5.5-centos7
    
    COPY post-init-scripts /usr/share/container-entrypoint/mariadb/post-init.d
    ```


Changing default locale
-----------------------

This Dockerfile will create a Docker image based on `ravensys/mariadb:5.5-centos7` with default locale set to 
`de_DE.UTF-8`.

```dockerfile
FROM ravensys/mariadb:5.5-centos7

RUN localedef -f UTF-8 -i de_DE de_DE.UTF-8
ENV LANG de_DE.UTF-8
```


Troubleshooting
---------------

The container initialization scripts and mysqld daemon logs to the standard output, so these are available in container 
log. This log can be examined by running:

```
$ docker logs <container>
```


See also
--------

Dockerfile and other sources for this container image are available on
https://github.com/ravensys/container-mariadb.
