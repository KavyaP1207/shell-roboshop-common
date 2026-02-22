#!/bin/bash



USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
START_TIME=$(date +%s)
MONGODB_HOST=moongodb.daws88s.sbs
MYSQL_HOST=mysql.daws88s.sbs
SCRIPT_DIR=$(pwd)
mkdir -p $LOGS_FOLDER
echo "Script started executed at: $(date)" | tee -a $LOG_FILE

check_root(){
if [ $USERID -ne 0 ]; then
    echo "ERROR:: Please run this script with root privilege"
    exit 1 # failure is other than 0
fi

}

VALIDATE(){ #functions receive inputs through args just like shell script args
   if [ $1 -ne 0 ]; then
   echo -e " $2 ... $R FAILURE $N" | tee -a $LOG_FILE
   exit 1
   else
    echo -e " $2 ... $G SUCCESS $N" | tee -a $LOG_FILE
   fi 
}

nodejs_setup(){
    dnf module disable nodejs -y &>>$LOG_FILE
    VALIDATE $? "disabling node js"
    dnf module enable nodejs:20 -y &>>$LOG_FILE
    VALIDATE $? "enabling node js "
    dnf install nodejs -y &>>$LOG_FILE
   VALIDATE $? "INSTALLING NODE JS"
   npm install &>>$LOG_FILE
   VALIDATE $? "install dependies"
}
java_setup(){
    dnf install maven -y &>>$LOG_FILE
    VALIDATE $? "INSTALLING MAVEN"
    mvn clean package
    VALIDATE $? "PACKNG THE APPLICATION"
    mv target/shipping-1.0.jar shipping.jar 
    VALIDATE $? "RENAMING THE ARTIFACTS"
}

python_setup(){
    dnf install python3 gcc python3-devel -y &>>$LOG_FILE
    VALIDATE $? "installing python"
    pip3 install -r requirements.txt &>>$LOG_FILE
    VALIDATE $? "installing requirements"
}

app_setup(){
    id roboshop &>>$LOG_FILE
    if [ $? -ne 0 ]; then 
       useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
       VALIDATE $? "system user "
    else
       echo -e "user already exist... $Y skippinggg $N"
    fi
    mkdir -p /app 
    VALIDATE $? "app directory "
    curl -o /tmp/$app_name.zip https://roboshop-artifacts.s3.amazonaws.com/$app_name-v3.zip &>>$LOG_FILE
    VALIDATE $? "dowloading $app_name applications "
    cd /app 
    VALIDATE $? "changing to app dir"
    rm -rf /app/*
    VALIDATE $? "removing existing code"
    unzip /tmp/$app_name.zip &>>$LOG_FILE
    VALIDATE $? "unzip $app_name"
}

systemd_setup(){
   cp $SCRIPT_DIR/$app_name.service /etc/systemd/system/$app_name.service
   VALIDATE $? "copy sys services "
   systemctl daemon-reload
   systemctl enable $app_name &>>$LOG_FILE
   VALIDATE $? "enabling $app_name" 
}
app_restart(){
    systemctl restart $app_name
    VALIDATE $? "restarted $app_name"
}

print_total_time(){
  END_TIME=$(date +%s)
  TOTAL_TIME=$(($END_TIME - $START_TIME))
  echo -e "script executed in : $TOTAL_TIME seconds $N"
}