rman target /  LOG=/bkp/LOG_RMAN_$DATA.log <<EOF
CONFIGURE RETENTION POLICY TO REDUNDANCY 1;
CONFIGURE BACKUP OPTIMIZATION ON;
CONFIGURE CONTROLFILE AUTOBACKUP ON;
CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '/bkp/%F';
CONFIGURE SNAPSHOT CONTROLFILE NAME TO '/bkp/snapcf_$ORACLE_SID.f';
run
{
allocate channel t1 type disk;
allocate channel t2 type disk;
allocate channel t3 type disk;
sql "create pfile=''/bkp/P_FILE_$SID.ORA'' from spfile";
sql 'alter system archive log current';
backup as compressed backupset database
format '/bkp/RMAN_%d_%Y%M%D_%s_%p.rman'
plus archivelog
format '/bkp/ARCH_%d_%Y%M%D_%s_%p.rman'
tag 'bkp_diario_arch';
release channel t1;
release channel t2;
release channel t3;
}
crosscheck archivelog all;
delete noprompt expired archivelog all;
delete noprompt archivelog all completed before 'sysdate-1';
crosscheck backup;
delete noprompt obsolete;
delete noprompt expired backupset;
EOF
