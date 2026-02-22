#!/bin/bash

source ./common.sh

check_root

dnf module disable redis -y &>>$LOG_FILE
VALIDATE $? "disabling default redis"
dnf module enable redis:7 -y &>>$LOG_FILE
VALIDATE $? "enabling redis"
dnf install redis -y &>>$LOG_FILE
VALIDATE $? "installing redis" 

sudo sed -i -e 's/127.0.0.1/0.0.0.0/g' \
-e 's/^protected-mode .*/protected-mode no/' \
/etc/redis/redis.conf

VALIDATE $? "allowing remote connection to redis"

systemctl enable redis &>>$LOG_FILE
VALIDATE $? "enabling redis"
systemctl start redis &>>$LOG_FILE
VALIDATE $? "starting redis"


print_total_time