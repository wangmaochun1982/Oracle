#!/bin/bash
week="`date +%w`"
echo $week

rman target / <<EOF
run{
	allocate channel ch1 device type disk;
	allocate channel ch2 device type disk;
	SQL'ALTER SYSTEM SWITCH LOGFILE';
	BACKUP AS COMPRESSED BACKUPSET INCREMENTAL LEVEL 1 ARCHIVELOG ALL FORMAT "/home/oracle/backup/data/arch_level_1_%u_$week" delete all input;
	RELEASE CHANNEL ch1;
	RELEASE CHANNEL	ch2;
}
