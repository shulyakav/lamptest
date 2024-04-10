#!/bin/bash


sudo yum update -y
sudo rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023
wget https://dev.mysql.com/get/mysql80-community-release-el7-3.noarch.rpm
sudo rpm -Uvh mysql80-community-release-el7-3.noarch.rpm
sudo yum install -y mysql-community-server
sudo yum install -y expect

sudo systemctl start mysqld
sudo systemctl enable mysqld

sleep 60
temp_pass=$(sudo grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}')
#echo "Temporary MySQL root password is: $temp_pass"



# Login to MySQL and reset root password and configure the database, user, and table
mysql -u root -p$temp_pass <<QUERY_INPUT
ALTER USER 'root'@'localhost' IDENTIFIED BY '${database_password}';
CREATE DATABASE ${database_name};
CREATE USER '${database_user}' IDENTIFIED BY '${database_password}';
GRANT ALL PRIVILEGES ON ${database_name}.* TO '${database_user}'@'%';
FLUSH PRIVILEGES;

USE ${database_name};
CREATE TABLE ${table_name} (
    id INT AUTO_INCREMENT PRIMARY KEY,
    data VARCHAR(255) NOT NULL
);
INSERT INTO ${table_name} (data) VALUES ('1'), ('created by Artem S');
QUERY_INPUT

##
mysql -u root -p$temp_pass --connect-expired-password <<QUERY_INPUT
ALTER USER 'root'@'localhost' IDENTIFIED BY 'n7*EHjMutGCbeA!WT_Tb';

CREATE DATABASE simpledb;
CREATE USER 'mqsqladmin' IDENTIFIED BY 'n7*EHjMutGCbeA!WT_Tb';
GRANT ALL PRIVILEGES ON simpledb.* TO 'mqsqladmin';
FLUSH PRIVILEGES;

USE simpledb;
CREATE TABLE simpletable (
    id INT AUTO_INCREMENT PRIMARY KEY,
    data VARCHAR(255) NOT NULL
);
INSERT INTO simpletable (data) VALUES ('1'), (' created by Artem S');
QUERY_INPUT
