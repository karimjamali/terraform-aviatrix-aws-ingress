#!/bin/bash
sudo su 
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sudo /etc/init.d/ssh restart
echo ubuntu:${password} | /usr/sbin/chpasswd
apt update && apt -y upgrade
apt -y install mysql-server
sed -i "s/.*bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
systemctl restart mysql
echo "CREATE DATABASE wordpress;
CREATE USER 'wordpress'@'%' IDENTIFIED BY 'Aviatrix';
GRANT ALL PRIVILEGES ON *.* TO wordpress;
FLUSH PRIVILEGES;" | mysql -u root
systemctl restart mysql


