MariaDB SQL database server Docker image
========================================

[![Build Stauts](https://api.travis-ci.org/ravensys/container-mariadb.svg?branch=master)](https://travis-ci.org/ravensys/container-mariadb/)

This repository contains Dockerfiles and scripts for MariaDB images based on CentOS.


Versions
--------

MariaDB versions provided:

* [MariaDB 10.1](10.1)
* [MariaDB 10.2](10.2)

CentOS versions supported:

* CentOS 7


Installation
------------

* **CentOS 7 based image**

    This image is available on DockerHub. To download it run:
    
    ```
    $ docker pull ravensys/mariadb:10.2-centos7
    ```

    To build a CentOS based MariaDB image from source run:
    
    ```
    $ git clone --recursive https://github.com/ravensys/container-mariadb
    $ cd container-mariadb
    $ make build VERSION=10.2
    ```

For using other versions of MariaDB just replace `10.2` value by particular version in commands above.


Usage
-----

For information about usage of Dockerfile for MariaDB 10.1 see [usage documentation](10.1).

For information about usage of Dockerfile for MariaDB 10.2 see [usage documentation](10.2).


Test
----

This repository also provides a test framework, which check basic functionality of MariaDB image.

* **CentOS 7 based image**

    ```
    $ cd container-mariadb
    $ make test VERSION=10.2
    ```
    
For using other versions of MariaDB just replace `10.2` value by particular version in commands above.


Credits
-------

This project is derived from [`mariadb-container`](https://github.com/sclorg/mariadb-container) by 
[SoftwareCollections.org](https://www.softwarecollections.org).
