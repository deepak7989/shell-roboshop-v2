#!/bin/bash

LOG_FOLDER="/var/log/roboshop" #creating folder #in this folder mongodb.sh will be created
sudo mkdir -p $LOG_FOLDER #inside var/log
sudo chown -R ec2-user:ec2-user $LOG_FOLDER # Set permission to ec2-user
sudo chmod -R 755 $LOG_FOLDER
LOGS_FILE="$LOG_FOLDER/$0.log"
SCRIPT_DIR=$PWD

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

echo -e "$TIMESTAMP [INFO] Script started"

check_root(){
    if [ $USERID -ne 0 ]; then
        echo -e "$TIMESTAMP [ERROR] $R Please run this script with root access $N" | tee -a $LOGS_FILE
        exit 1
    fi
}

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$TIMESTAMP [ERROR] $2 ... $R FAILURE $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$TIMESTAMP [INFO] $2 ... $G SUCCESS $N" | tee -a $LOGS_FILE
    fi
}

print_total_time(){
    echo -e "$TIMESTAMP [INFO] Script executed in $G $SECONDS seconds $N"
}

app_setup(){
    id roboshop &>> $LOGS_FILE
    if [ $? -ne 0 ]; then
        useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOGS_FILE
        VALIDATE $? "Creating roboshop system user"
    else
        echo -e "System user roboshop alredy created ... $Y SKIPPING $N"
    fi

    rm -rf /app
    VALIDATE $? "Removing existing code"

    rm -rf /tmp/$app_name.zip
    VALIDATE $? "Removed $app_name zip"

    mkdir -p /app &>> $LOGS_FILE
    VALIDATE $? "Creating app directory"

    curl -o /tmp/$app_name.zip https://roboshop-artifacts.s3.amazonaws.com/$app_name-v3.zip &>> $LOGS_FILE
    cd /app 
    unzip /tmp/$app_name.zip &>> $LOGS_FILE
    VALIDATE $? "Dowloaded and extracted $app_name code"
}

nodejs_setup(){
    dnf module disable nodejs -y &>> $LOGS_FILE
    dnf module enable nodejs:20 -y &>> $LOGS_FILE
    dnf install nodejs -y &>> $LOGS_FILE
    VALIDATE $? "Instaling NodeJS:20"
    npm install &>> $LOGS_FILE
    VALIDATE $? "Installing dependencies"
}

systemd_setup(){
    cp $SCRIPT_DIR/$app_name.service /etc/systemd/system/$app_name.service
    VALIDATE $? "Created systemctl service"

    systemctl daemon-reload
    systemctl enable $app_name &>> $LOGS_FILE
    VALIDATE $? "Enabling $app_name"
}

app_restart(){
    systemctl restart $app_name
    VALIDATE $? "$app_name restarting"
}

java_setup(){
    dnf install maven -y &>> $LOGS_FILE

    mvn clean package &>> $LOGS_FILE
    mv target/shipping-1.0.jar shipping.jar
    VALIDATE $? "Installing dependencies"
}