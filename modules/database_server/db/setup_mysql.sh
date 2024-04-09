#!/bin/bash


sudo yum update -y
sudo yum install -y mysql-server
sudo systemctl start mysqld
sudo systemctl enable mysqld

# Secure MySQL installation automatically (example settings)
sudo mysql_secure_installation <<EOF

y
secret
secret
y
y
y
y
EOF

# Login to MySQL and configure the database, user, and table
sudo mysql -u root -psecret <<QUERY_INPUT
CREATE DATABASE ${database_name};
CREATE USER '${database_user}' IDENTIFIED BY '${database_password}';
GRANT ALL PRIVILEGES ON ${database_name}.* TO '${database_user}';
FLUSH PRIVILEGES;

USE ${database_name};
CREATE TABLE ${table_name} (
    id INT AUTO_INCREMENT PRIMARY KEY,
    data VARCHAR(255) NOT NULL
);
INSERT INTO sample_table (data) VALUES (' created by'), ('Artem S');
QUERY_INPUT
