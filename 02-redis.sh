#!/bin/bash

source ./common.sh

check_root

dnf module disable redis -y &>> $LOGS_FILE 
dnf module enable redis:7 -y &>> $LOGS_FILE
dnf install redis -y &>> $LOGS_FILE
VALIDATE $? "Installin Redis:7"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e 's/protected-mode yes/protected-mode no/g' /etc/redis/redis.conf &>> $LOGS_FILE
VALIDATE $? "Allowing remote coonections"

systemctl enable redis &>> $LOGS_FILE
systemctl start redis &>> $LOGS_FILE
VALIDATE $? "Started Redis"

print_total_time