#!/bin/bash

app_name=catalogue
source ./common.sh
check_root

app_setup
nodejs_setup
systemd_setup

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Added Mongo repo"

dnf install mongodb-mongosh -y &>> $LOGS_FILE
VALIDATE $? "Install Mongodb client"

INDEX=$(mongosh --host mongodb.deep90s.online --eval 'db.getMongo().getDBNames().indexOf("catalogue")')

if [ $INDEX -lt 0 ]; then
    mongosh --host mongodb.deep90s.online </app/db/master-data.js &>> $LOGS_FILE
    VALIDATE $? "Load products"
else
    echo -e "Products alredy loaded ... $Y SKIPPING $N"
fi
app_restart
print_total_time