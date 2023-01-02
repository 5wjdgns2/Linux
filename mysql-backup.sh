#!/bin/bash

cd /svcroot/sharedata/SCRIPT/mysql

# Database credentials
user="backupuser"
password="Qordjq_3306"

dbport[0]=13306
dbport[1]=13406
dbport[2]=13506

DBNAME[0]="cm_db"
DBNAME[1]="mynadb"
DBNAME[2]="sta_db"

LOGFILE[0]="/svcroot/sharedata/SCRIPT/mysql/dev/mysql_backup_dev1/mysql_backup_dev1.log"
LOGFILE[1]="/svcroot/sharedata/SCRIPT/mysql/dev/mysql_backup_dev1/mysql_backup_dev1.log"
LOGFILE[2]="/svcroot/sharedata/SCRIPT/mysql/dev/mysql_backup_dev1/mysql_backup_dev1.log"

# Other options
backup_path="/svcroot/sharedata/SCRIPT/mysql/dev/mysql_backup_dev1"
CDATE=$(date +"%Y-%m-%d")

# To create a new directory into backup directory location
mkdir -p ${backup_path}/${CDATE}

# Dump database into SQL file
function create_backup(){
        arg1=${1}
        arg2=${2}
        result=0
        docker exec -t `docker ps -a |grep ${arg1} | awk '{print $1}'` mysqldump --single-transaction --add-drop-table --force --user=${user} --password=${password} --all-databases > ${backup_path}/${CDATE}/${arg1}_${arg2}.sql || result=$((result+1))
        sed -i '1d' ${backup_path}/${CDATE}/${arg1}_${arg2}.sql

        return ${result}
}

# Delete files & directories older than 7 days
function delete_old_backup(){
        result=0
        find ${backup_path} -maxdepth 1 -mtime +7 -type d -exec rm -rf {} \; && echo "" || result=$((result+1))
        return ${result}
}

# Backup all host
error_flag=0
for (( i=0 ;i < ${#dbport[*]} ; i++ ))
do
        create_backup ${dbport[$i]} ${DBNAME[$i]}
        if [ $? -eq 0 ];then
        echo "[`date`] [${dbport[i]} - ${DBNAME[$i]}] Creation of backup is successful!!" | tee -a ${LOGFILE[$i]}
else
        echo "[`date`] [${dbport[i]} - ${DBNAME[$i]}] Creation of backup is failed!!" | tee -a ${LOGFILE[$i]}
        error_flag=1
fi
done

# If success backup all host then run delete old backup function
if [ ${error_flag} != 1 ];then
        delete_old_backup
        if [ $? -eq 0 ];then
                echo "[`date`] Deletion of old mysql backup is successful!!" | tee -a /var/log/messages
        else
                echo "[`date`] Error!! Deletion of old mysql backup is failed!" | tee -a /var/log/messages
        fi
fi
