1.清除SBT过期备份

```sql
rlwrap rman target /
RMAN> allocate channel for maintenance device type sbt
 parms 'SBT_LIBRARY=oracle.disksbt, ENV=(BACKUP_DIR=/tmp)';
RMAN> crosscheck backup;
RMAN> delete expired backup;
 RMAN> crosscheck archivelog all;
RMAN> delete expired archivelog all;
```

2.源端进行全备

```sql
   run{
        allocate channel ch1 type disk;
        allocate channel ch2 type disk;
        allocate channel ch3 type disk;
        allocate channel ch4 type disk;
        sql  'alter system checkpoint';
        sql 'alter system switch logfile';
        sql 'alter system archive log current';
        backup as compressed backupset database format   '/backup/rman/db_%d_%T_%s_%p.bak';
       sql 'alter system archive log current';
       sql 'alter system archive log current';
       backup as compressed backupset archivelog all format   '/backup/rman/arc_%d_%T_%s_%p.bak';
       backup current controlfile format   '/backup/rman/ctl_%d_%T_%s_%p.bak';    
       backup spfile format '/backup/rman/spfile_%d_%T_%s_%p.bak';   
       release channel ch1;
       release channel ch2;
       release channel ch3;
       release channel ch4;
    }
```
3.打包备份文件，并传到目标数据库
    
```sql
scp /rman/* oracle@10.2.1.55:/rman/ --将备份出来的信息传到目标库的存放地址
scp orapwatmesa 10.2.1.55:$ORACLE_HOME/dbs
scp /oracle/arch/* oracle@10.2.1.55:/backup/arch/
```

4.目标端设置DBID并启动到nomount状态

```sql
$ vi initatmesa.ora
$ cat initweb.ora
*.db_name='atmesa'
$ sqlplus '/ as sysdba'
SQL>startup nomount;
$ rman target /
RMAN> set DBID=3212553356;
RMAN> restore spfile from '/rman/spfile_%d_%T_%s_%p.bak';
RMAN> shutdown;
SQL> create pfile from spfile;
[oracle@m1 dbs]$ vi initatmesa.ora

[oracle@atmesa]$ mkdir -p /u01/app/oracle/admin/atmesa/adump
[oracle@atmesa]$ mkdir -p /u01/app/oracle/admin/atmesa/dpdump
SQL> create spfile from pfile;
[oracle@m1 dbs]$ rm -rf spfileatmesa.ora
SQL> startup nomount;

```


5.恢复控制文件并启动到mount状态

```sql
$ rman target /
RMAN> set dbid 3212553356
RMAN> startup nomount
RMAN> restore controlfile from '/rman/ctl_ATMESA_20220506_31173_1.bak';
RMAN> alter database mount;
```

6.查看备份集开始恢复数据文件

```sql
RMAN> list backup summary;

MAN> allocate channel for maintenance device type sbt parms 'SBT_LIBRARY=oracle.disksbt, ENV=(BACKUP_DIR=/tmp)';
RMAN> delete expired backup;
也可以查SCN
SQL> col name for a50
SQL> col checkpoint_change# for 99999999999999999
SQL> select name,checkpoint_change# from v$datafile;控制文件SCN
```

SQL> select name,checkpoint_change# from v$datafile_header;数据文件SCN
SQL>select 'set until scn '||max(next_change#)||';' from v$backup_archivelog_details;


RMAN> list backup summary;
~~~~~~从源库搜修改下路径
RMAN  SET NEW NAME
    
sqlplus "/as sysdba"
set linesize 130 pagesize 2000
set trimspool on
set echo off
set verify off
set timing off
set feedback off
set head off
set echo off
spool /tmp/renfile.sql
select 'set newname for datafile ' || FILE# || ' to ' ||'''/u02/app/oracle/oradata/atmesa/' || substr(name,instr(name, '/', -1) + 1) ||''' ;' file_name from v$datafile
union all
select 'set newname for tempfile ' || file# ||  ' to ' ||'''/u02/app/oracle/oradata/atmesa/temp01.dbf'||'''; ' cmd  from v$tempfile;
spool off
```

```sql
run{
allocate channel d1 device type disk;
allocate channel d2 device type disk;
catalog start with '/rman/atmesa';
set newname for datafile 1 to '/u02/app/oracle/oradata/atmesa/system01.dbf';
set newname for datafile 2 to '/u02/app/oracle/oradata/atmesa/sysaux01.dbf';
set newname for datafile 3 to '/u02/app/oracle/oradata/atmesa/TS_EMES_C01.DBF';
set newname for datafile 4 to '/u02/app/oracle/oradata/atmesa/users01.dbf';
set newname for datafile 6 to '/u02/app/oracle/oradata/atmesa/DEFRAG.DBF';
set newname for datafile 7 to '/u02/app/oracle/oradata/atmesa/undo01.dbf';
set newname for datafile 8 to '/u02/app/oracle/oradata/atmesa/TS_EMES_CIDX01.DBF';
set newname for datafile 10 to '/u02/app/oracle/oradata/atmesa/TS_EMES_H01.DBF';
set newname for datafile 11 to '/u02/app/oracle/oradata/atmesa/TS_EMES_H02.DBF';
set newname for datafile 12 to '/u02/app/oracle/oradata/atmesa/TS_EMES_H03.DBF';
set newname for datafile 13 to '/u02/app/oracle/oradata/atmesa/PARTITION_H01.DBF';
set newname for datafile 14 to '/u02/app/oracle/oradata/atmesa/PARTITION_H02.DBF';
set newname for datafile 15 to '/u02/app/oracle/oradata/atmesa/PARTITION_H03.DBF';
set newname for datafile 16 to '/u02/app/oracle/oradata/atmesa/QA_TS_EMES_H01.DBF';
set newname for datafile 17 to '/u02/app/oracle/oradata/atmesa/TS_EMES_HIDX01.DBF';
set newname for datafile 18 to '/u02/app/oracle/oradata/atmesa/TS_EMES_HIDX02.DBF';
set newname for datafile 19 to '/u02/app/oracle/oradata/atmesa/TS_EMES_HIDX03.DBF';
set newname for datafile 20 to '/u02/app/oracle/oradata/atmesa/PARTITIONINDEX_H01.DBF';
set newname for datafile 21 to '/u02/app/oracle/oradata/atmesa/PARTITIONINDEX_H02.DBF';
set newname for datafile 22 to '/u02/app/oracle/oradata/atmesa/PARTITIONINDEX_H03.DBF';
set newname for datafile 23 to '/u02/app/oracle/oradata/atmesa/QA_TS_EMES_HIDX01.DBF';
set newname for datafile 24 to '/u02/app/oracle/oradata/atmesa/TS_EMES_P01.DBF';
set newname for datafile 25 to '/u02/app/oracle/oradata/atmesa/TS_EMES_P02.DBF';
set newname for datafile 26 to '/u02/app/oracle/oradata/atmesa/PARTITION01.DBF';
set newname for datafile 27 to '/u02/app/oracle/oradata/atmesa/PARTITION02.DBF';
set newname for datafile 28 to '/u02/app/oracle/oradata/atmesa/PARTITION03.DBF';
set newname for datafile 29 to '/u02/app/oracle/oradata/atmesa/QA_TS_EMES_PIDX01.DBF';
set newname for datafile 30 to '/u02/app/oracle/oradata/atmesa/QA_TS_EMES_PIDX02.DBF';
set newname for datafile 31 to '/u02/app/oracle/oradata/atmesa/QA_TS_EMES_P01.DBF';
set newname for datafile 32 to '/u02/app/oracle/oradata/atmesa/DT_TS_EMES_P01.DBF';
set newname for datafile 33 to '/u02/app/oracle/oradata/atmesa/TS_EMES_PIDX01.DBF';
set newname for datafile 34 to '/u02/app/oracle/oradata/atmesa/TS_EMES_PIDX02.DBF';
set newname for datafile 35 to '/u02/app/oracle/oradata/atmesa/DT_TS_EMES_PIDX01.DBF';
set newname for datafile 36 to '/u02/app/oracle/oradata/atmesa/PARTITIONINDEX01.DBF';
set newname for datafile 37 to '/u02/app/oracle/oradata/atmesa/PARTITIONINDEX02.DBF';
set newname for datafile 38 to '/u02/app/oracle/oradata/atmesa/TS_EMES_CIIDX01.DBF';
set newname for datafile 39 to '/u02/app/oracle/oradata/atmesa/TS_EMES_CI01.DBF' ;
set newname for datafile 40 to '/u02/app/oracle/oradata/atmesa/DT_TS_EMES_PIDX02.DBF';
set newname for datafile 41 to '/u02/app/oracle/oradata/atmesa/TS_EMES_W01.DBF';
set newname for datafile 42 to '/u02/app/oracle/oradata/atmesa/TS_EMES_WIDX01.DBF';
set newname for tempfile 1 to '/u02/app/oracle/oradata/atmesa/temp01.DBF';
restore database;
switch datafile all;
switch tempfile all;
release channel d1;
release channel d2;
}
```

```sql
RMAN> recover database;

RMAN-06054: media recovery requesting unknown archived log for thread 1 with sequence 8 and starting SCN of 241384
---报错原因：RMAN备份不会备份当前的redo logfile文件，异机恢复时找不到redo logfile，所以报错rman-06054
---解决方案：基于SCN的不完全恢复

RMAN> run {  
       set until scn 241384;  
        recover database;  
      }  
      
SQL> select name,checkpoint_change# from v$datafile;控制文件SCN

SQL> select name,checkpoint_change# from v$datafile_header;数据文件SCN

SQL>select 'set until scn '||max(next_change#)||';' from v$backup_archivelog_details;

执行备份归档的时间点
Relocate all the online redo logs


SQL> select * from v$logfile;
SQL> alter database rename file 'old redo log path and name' to 'new redo log path and name';
SQL>alter database rename file '/oracle/data/atmesa/system/redo01.log' to '/u02/app/oracle/oradata/atmesa/redo01.log';
SQL>alter database rename file '/oracle/data/atmesa/system/redo02.log' to '/u02/app/oracle/oradata/atmesa/redo02.log';
SQL>alter database rename file '/oracle/data/atmesa/system/redo03.log' to '/u02/app/oracle/oradata/atmesa/redo03.log';
SQL>alter database clear logfile group 1;

RMAN> alter database open resetlogs;
```


###############底下为一些注解


v$archved_log是控制文件信息，mount后可查查看归档日志备份的状态，查看能最大能恢复到哪个sequence

```sql
SQL> select max(sequence#) from v$archived_log;
RMAN> list backup of archivelog all;
把拷贝到新机器的备份文件注册到（刚恢复的）控制文件中（redolog不能被注册，所以最后有报错，没有关系）：
RMAN> catalog start with "d:\backup\rman\";


sql'alter session set nls_date_format="yyyy-mm-dd hh24:mi:ss"';
set until time '2021-07-21 18:08:53';
recover database;

SQL> select name,checkpoint_change# from v$datafile;控制文件SCN
SQL> select name,checkpoint_change# from v$datafile_header;数据文件SCN
SQL>select 'set until scn '||max(next_change#)||';' from v$backup_archivelog_details;

SQL> alter system archive log current; -->对当前日志进行归档
-->下面的查询可知产生新的归档日志29  
SQL> SELECT name,sequence# seq#,status,completion_time FROM v$archived_log where sequence#>=28;

-->应证归档日志中包含记录Robinson 10:09:53
SQL> ho strings /backup/arch/o1_mf_1_29_8xdbnqx9_.arc | grep "Robinson" Robinson


```

```sql

1.RMAN  SET NEW NAME
    
sqlplus "/as sysdba"
set linesize 130 pagesize 2000
set trimspool on
set echo off
set verify off
set timing off
set feedback off
set head off
set echo off
spool /tmp/renfile.sql
select 'set newname for datafile ' || FILE# || ' to ' ||'''/u02/app/oracle/oradata/atmesa/' || substr(name,instr(name, '/', -1) + 1) ||''' ;' file_name from v$datafile
union all
select 'set newname for tempfile ' || file# ||  ' to ' ||'''/u02/app/oracle/oradata/atmesa/temp01.dbf'||'''; ' cmd  from v$tempfile;
spool off

2.SET NEW NAME

set newname for datafile 20 to '/u02/app/oracle/oradata/atmesa/PARTITIONINDEX_H01.DBF' ;
set newname for datafile 21 to '/u02/app/oracle/oradata/atmesa/PARTITIONINDEX_H02.DBF' ;
set newname for datafile 22 to '/u02/app/oracle/oradata/atmesa/PARTITIONINDEX_H03.DBF' ;
set newname for datafile 23 to '/u02/app/oracle/oradata/atmesa/QA_TS_EMES_HIDX01.DBF' ;
set newname for datafile 24 to '/u02/app/oracle/oradata/atmesa/TS_EMES_P01.DBF' ;
set newname for datafile 25 to '/u02/app/oracle/oradata/atmesa/TS_EMES_P02.DBF' ;
set newname for datafile 26 to '/u02/app/oracle/oradata/atmesa/PARTITION01.DBF' ;
set newname for datafile 27 to '/u02/app/oracle/oradata/atmesa/PARTITION02.DBF' ;
set newname for datafile 28 to '/u02/app/oracle/oradata/atmesa/PARTITION03.DBF' ;
set newname for datafile 29 to '/u02/app/oracle/oradata/atmesa/QA_TS_EMES_PIDX01.DBF' ;
set newname for datafile 30 to '/u02/app/oracle/oradata/atmesa/QA_TS_EMES_PIDX02.DBF' ;
set newname for datafile 31 to '/u02/app/oracle/oradata/atmesa/QA_TS_EMES_P01.DBF' ;
set newname for datafile 32 to '/u02/app/oracle/oradata/atmesa/DT_TS_EMES_P01.DBF' ;
set newname for datafile 33 to '/u02/app/oracle/oradata/atmesa/TS_EMES_PIDX01.DBF' ;
set newname for datafile 34 to '/u02/app/oracle/oradata/atmesa/TS_EMES_PIDX02.DBF' ;
set newname for datafile 35 to '/u02/app/oracle/oradata/atmesa/DT_TS_EMES_PIDX01.DBF' ;
set newname for datafile 36 to '/u02/app/oracle/oradata/atmesa/PARTITIONINDEX01.DBF' ;
set newname for datafile 37 to '/u02/app/oracle/oradata/atmesa/PARTITIONINDEX02.DBF' ;
set newname for datafile 38 to '/u02/app/oracle/oradata/atmesa/TS_EMES_CIIDX01.DBF' ;
set newname for datafile 39 to '/u02/app/oracle/oradata/atmesa/TS_EMES_CI01.DBF' ;
set newname for datafile 40 to '/u02/app/oracle/oradata/atmesa/DT_TS_EMES_PIDX02.DBF' ;
set newname for datafile 41 to '/u02/app/oracle/oradata/atmesa/TS_EMES_W01.DBF' ;
set newname for datafile 42 to '/u02/app/oracle/oradata/atmesa/TS_EMES_WIDX01.DBF' ;
set newname for tempfile 1 to '/u02/app/oracle/oradata/atmesa/temp01.DBF';

```
```sql
3.restore run

run{
allocate channel d1 device type disk;
allocate channel d2 device type disk;
catalog start with '/backup/L0/';
set newname for datafile 20 to '/u02/app/oracle/oradata/atmesa/PARTITIONINDEX_H01.DBF' ;
set newname for datafile 21 to '/u02/app/oracle/oradata/atmesa/PARTITIONINDEX_H02.DBF' ;
set newname for datafile 22 to '/u02/app/oracle/oradata/atmesa/PARTITIONINDEX_H03.DBF' ;
set newname for datafile 23 to '/u02/app/oracle/oradata/atmesa/QA_TS_EMES_HIDX01.DBF' ;
set newname for datafile 24 to '/u02/app/oracle/oradata/atmesa/TS_EMES_P01.DBF' ;
set newname for datafile 25 to '/u02/app/oracle/oradata/atmesa/TS_EMES_P02.DBF' ;
set newname for datafile 26 to '/u02/app/oracle/oradata/atmesa/PARTITION01.DBF' ;
set newname for datafile 27 to '/u02/app/oracle/oradata/atmesa/PARTITION02.DBF' ;
set newname for datafile 28 to '/u02/app/oracle/oradata/atmesa/PARTITION03.DBF' ;
set newname for datafile 29 to '/u02/app/oracle/oradata/atmesa/QA_TS_EMES_PIDX01.DBF' ;
set newname for datafile 30 to '/u02/app/oracle/oradata/atmesa/QA_TS_EMES_PIDX02.DBF' ;
set newname for datafile 31 to '/u02/app/oracle/oradata/atmesa/QA_TS_EMES_P01.DBF' ;
set newname for datafile 32 to '/u02/app/oracle/oradata/atmesa/DT_TS_EMES_P01.DBF' ;
set newname for datafile 33 to '/u02/app/oracle/oradata/atmesa/TS_EMES_PIDX01.DBF' ;
set newname for datafile 34 to '/u02/app/oracle/oradata/atmesa/TS_EMES_PIDX02.DBF' ;
set newname for datafile 35 to '/u02/app/oracle/oradata/atmesa/DT_TS_EMES_PIDX01.DBF' ;
set newname for datafile 36 to '/u02/app/oracle/oradata/atmesa/PARTITIONINDEX01.DBF' ;
set newname for datafile 37 to '/u02/app/oracle/oradata/atmesa/PARTITIONINDEX02.DBF' ;
set newname for datafile 38 to '/u02/app/oracle/oradata/atmesa/TS_EMES_CIIDX01.DBF' ;
set newname for datafile 39 to '/u02/app/oracle/oradata/atmesa/TS_EMES_CI01.DBF' ;
set newname for datafile 40 to '/u02/app/oracle/oradata/atmesa/DT_TS_EMES_PIDX02.DBF' ;
set newname for datafile 41 to '/u02/app/oracle/oradata/atmesa/TS_EMES_W01.DBF' ;
set newname for datafile 42 to '/u02/app/oracle/oradata/atmesa/TS_EMES_WIDX01.DBF' ;
set newname for tempfile 1 to '/u02/app/oracle/oradata/atmesa/temp01.DBF';
sql'alter session set nls_date_format="yyyy-mm-dd hh24:mi:ss"';
set until time '2021-07-21 18:08:53';
restore database;
switch datafile all;
switch tempfile all;
recover database;
release channel d1;
release channel d2;
}

```




    
