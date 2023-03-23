#!/bin/bash

##-------------------
##rman backup level 0
##
##	wang.jiaming
##------------------

logfile="/db_backup/backup/log/level_0_`date +%Y-%m-%d`"

if [! -d $logfile]; then
	mkdir $logfile
fi


rman target / <<EOF
run{
	allocate channel ch1 device type disk;
	allocate channel ch2 device type disk;
	backup as compressed backupset incremental level 0 tablespace gdyc_drug_usage format '/db_backup/backup/data/gdyc_drug_usage_level_0_%u';
	backup as compressed backupset incremental level 0 tablespace drug_gdyc format '/db_backup/backup/data/drug_gdyc_level_0_%u';
	backup as compressed backupset incremental level 0 tablespace drug_stat format '/db_backup/backup/data/drug_stat_level_0_%u';
	backup as compressed backupset incremental level 0 tablespace drug_training format '/db_backup/backup/data/drug_training_level_0_%u';
	backup as compressed backupset incremental level 0 tablespace gdyc_country format '/db_backup/backup/data/gdyc_country_level_0_%u';
	backup as compressed backupset incremental level 0 tablespace gdyc_pay format '/db_backup/backup/data/gdyc_pay_level_0_%u';
	backup as compressed backupset incremental level 0 tablespace rhin format '/db_backup/backup/data/rhin_level_0_%u';
	backup as compressed backupset incremental level 0 tablespace t_cfw2008 format '/db_backup/backup/data/t_cfw2008_level_0_%u';
	backup as compressed backupset incremental level 0 tablespace t_wjs format '/db_backup/backup/data/t_wjs_level_0_%u';
	SQL'ALTER SYSTEM SWITCH LOGFILE';
	backup as compressed backupset incremental level 0 archivelog all format'/db_backup/backup/data/arch_level_0_%u' delete all input;
	release channel ch1;
	release channel ch2;
}
quit
EOF 

## delete level 1
for level_1_filePath in `find ./data/ -name arch_level_1_*`
do
	echo "[`date +%Y-%m-%d`]delete ${level_1_filePath}">>$logfile
	rm $level_1_filePath
done
## delete old level 0
for filePath in `find ./data/ -name level_0_\* -mtime +3`
do
	echo "[`date +%Y-%m-%d`]delete ${filePath}">>$logfile
	rm $filePath
done

for archFilePath in `find ./data/ -name arch_level_0_\* -mtime +3`
do
	echo "[`date +%Y-%m-%d`]delete ${archFilePath}">>$logfile
	rm $archFilePath
done
