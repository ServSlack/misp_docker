MISP Docker Ubuntu 24.04

Project created by Weliton Souza, please give the credits and lets coonect " https://www.linkedin.com/in/weliton-souza/ "

This project can be used to create two Docker containers running Ubuntu 24.04 with MISP ("Malware Information Sharing Platform").

The MISP containers needs at least a MySQL container to store the data. By default it listen to port 443 and port 80, which is redirected to 443.

The build is based on Ubuntu 24.04 and will install all the required components, using the " INSTALL.sh " script.

Follow configurations and improvements performed:

    Optimization of the PHP environment (php.ini) to match the MISP recommended values

    Creation of the MySQL database with latest MariaDB version.

    Configure Static IPs for MISP_WEB and MISP_DB.

    Enabled new " SimpleBackGroudJobs " as default way to manage Workers

    Generation of the admin PGP key

    Enabled password complexity

    Installation and Enabled MISP Modules

    Installation and Configuration of CLAMAV

    Installation and Configuration of cron

    Installation and Configuration of rsyslog

    Installation and Tunning about all Security Audit, PHP Settings, PHP Extensions, PHP Dependencies and Attachment scan module.

    Defining default Passwords really Strong with long 65 carachters:
        GPG_PASSPHRASE
        SECURITY_ENCRYPTION_KEY
        MYSQL_PASSWORD
        MYSQL_ROOT_PASSWORD

    MISP_DB Container:
        Enable MariaDB " performance_schema "
        Include " my.cnf " tunning filed:
            It will redirect 50% of CPU to be used by " innodb_buffer_pool_instances, innodb_read_io_threads and innodb_write_io_threads "
            It will redirect 60% of POD server memory directly for Database
                If you want you can change this value directly on " misp_db " container inside file ( /etc/bash.bashrc ) and search from the lasts two variables ( " num_cpu " and " ram_total " )

Building your image and containers: Only RUN one by one of those files in the follow order and wait finish:

$ ( 1_Install_Docker.sh    x    2_Build_MISP_Image.sh    3_Create_MISP_Containers.sh )

$ 1-) If you don´t have Docker installed yeat only run " 1_Install_Docker.sh "
 
$ 2-) Once you have Docker installed propertly RUN: " 2_Build_MISP_Image.sh "

$ 3-) After complete BUILD Image RUN: " 3_Create_MISP_Containers.sh " to create MISP Containers.

$ 4-) When image below apears you can access your instance directly using your IP as example: " https://192.168.1.5 "
$ ATTENTION !!!! ---> Will be generated a file asked " password.txt " and I recommend you save this information in some Key Vault and after REMOVE the file.

# Building your image

## Fetch files
```
$ git clone https://github.com/ServSlack/misp_docker_ubuntu_24_04
$ cd misp_docker_ubuntu_24_04
$ chmod +x *.sh
$ chmod +x web/*.sh
$ chmod +x files/*.sh
```

## Install Docker
```
$ ./1_Install_Docker.sh

## Build MISP Images
```
$ ./2-Build_MISP_Image.sh

## Run containers
```
$ ./3-Create_MISP_Containers.sh
```
