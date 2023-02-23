常用DBA脚本
1、查看表空间的名称及大小
　　select t.tablespace_name, round(sum(bytes/(1024*1024)),0) ts_size
    from dba_tablespaces t, dba_data_files d
    where t.tablespace_name = d.tablespace_name
    group by t.tablespace_name;

2、查看表空间物理文件的名称及大小
    select tablespace_name, file_id, file_name, 
    round(bytes/(1024*1024),0) total_space 
    from dba_data_files 
    order by tablespace_name; 

查询数据库的实际大小
给出以 GB 为单位的数据库的实际大小
SELECT SUM (bytes) / 1024 / 1024 / 1024 AS GB FROM dba_data_files;

查询数据库中数据占用的大小或者是数据库使用细节
给出在数据库中数据占据的空间大小
SELECT SUM (bytes) / 1024 / 1024 / 1024 AS GB FROM dba_segments;

3、查看回滚段名称及大小
　　select segment_name, tablespace_name, r.status,
　　(initial_extent/1024) InitialExtent,(next_extent/1024) NextExtent,
　　max_extents, v.curext CurExtent
　　From dba_rollback_segs r, v$rollstat v
　　Where r.segment_id = v.usn(+)
　　order by segment_name ;

4、查看控制文件
　　select name from v$controlfile;

5、查看日志文件
　　select member from v$logfile;

6、查看表空间的使用情况
　　select sum(bytes)/(1024*1024) as free_space,tablespace_name
    from dba_free_space
    group by tablespace_name;

SELECT A.TABLESPACE_NAME,A.BYTES TOTAL,B.BYTES USED, C.BYTES FREE,
(B.BYTES*100)/A.BYTES "% USED",(C.BYTES*100)/A.BYTES "% FREE"
FROM SYS.SM$TS_AVAIL A,SYS.SM$TS_USED B,SYS.SM$TS_FREE C
WHERE A.TABLESPACE_NAME=B.TABLESPACE_NAME AND A.TABLESPACE_NAME=C.TABLESPACE_NAME;

7、查看数据库库对象
　　select owner, object_type, status, count(*) count# from all_objects group by owner, object_type, status;

8、查看数据库的版本　
　　Select version FROM Product_component_version
　　Where SUBSTR(PRODUCT,1,6)='Oracle';

9、查看数据库的创建日期和归档方式
Select Created, Log_Mode, Log_Mode From V$Database;

10、捕捉运行很久的SQL
column username format a12
column opname format a16
column progress format a8

select username,sid,opname,
round(sofar*100 / totalwork,0) || '%' as progress,
time_remaining,sql_text
from v$session_longops , v$sql
where time_remaining <> 0
and sql_address = address
and sql_hash_value = hash_value

2、 11、查看数据表的参数信息
SELECT partition_name, high_value, high_value_length, tablespace_name,
pct_free, pct_used, ini_trans, max_trans, initial_extent,
next_extent, min_extent, max_extent, pct_increase, FREELISTS,
freelist_groups, LOGGING, BUFFER_POOL, num_rows, blocks,
empty_blocks, avg_space, chain_cnt, avg_row_len, sample_size,
last_analyzed
FROM dba_tab_partitions
--WHERE table_name = :tname AND table_owner = :towner
ORDER BY partition_position

12.查看还没提交的事务
　　select * from v$locked_object;
　　select * from v$transaction;

13。查找object为哪些进程所用
select
p.spid,
s.sid,
s.serial# serial_num,
s.username user_name,
a.type object_type,
s.osuser os_user_name,
a.owner,
a.object object_name,
decode(sign(48 - command),
1,
to_char(command), 'Action Code #' || to_char(command) ) action,
p.program oracle_process,
s.terminal terminal,
s.program program,
s.status session_status
from v$session s, v$access a, v$process p
where s.paddr = p.addr and
s.type = 'USER' and
a.sid = s.sid and
a.object='SUBSCRIBER_ATTR'
order by s.username, s.osuser

14。回滚段查看
select rownum, sys.dba_rollback_segs.segment_name Name, v$rollstat.extents
Extents, v$rollstat.rssize Size_in_Bytes, v$rollstat.xacts XActs,
v$rollstat.gets Gets, v$rollstat.waits Waits, v$rollstat.writes Writes,
sys.dba_rollback_segs.status status from v$rollstat, sys.dba_rollback_segs,
v$rollname where v$rollname.name(+) = sys.dba_rollback_segs.segment_name and
v$rollstat.usn (+) = v$rollname.usn order by rownum

15。耗资源的进程（top session）
select s.schemaname schema_name, decode(sign(48 - command), 1,
to_char(command), 'Action Code #' || to_char(command) ) action, status
session_status, s.osuser os_user_name, s.sid, p.spid , s.serial# serial_num,
nvl(s.username, '[Oracle process]') user_name, s.terminal terminal,
s.program program, st.value criteria_value from v$sesstat st, v$session s , v$process p
where st.sid = s.sid and st.statistic# = to_number('38') and ('ALL' = 'ALL'
or s.status = 'ALL') and p.addr = s.paddr order by st.value desc, p.spid asc, s.username asc, s.osuser asc

16。查看锁（lock）情况
select /*+ RULE */ ls.osuser os_user_name, ls.username user_name,
decode(ls.type, 'RW', 'Row wait enqueue lock', 'TM', 'DML enqueue lock', 'TX',
'Transaction enqueue lock', 'UL', 'User supplied lock') lock_type,
o.object_name object, decode(ls.lmode, 1, null, 2, 'Row Share', 3,
'Row Exclusive', 4, 'Share', 5, 'Share Row Exclusive', 6, 'Exclusive', null)
lock_mode, o.owner, ls.sid, ls.serial# serial_num, ls.id1, ls.id2
from sys.dba_objects o, ( select s.osuser, s.username, l.type,
l.lmode, s.sid, s.serial#, l.id1, l.id2 from v$session s,
v$lock l where s.sid = l.sid ) ls where o.object_id = ls.id1 and o.owner
<> 'SYS' order by o.owner, o.object_name

17。查看等待（wait）情况
SELECT v$waitstat.class, v$waitstat.count count, SUM(v$sysstat.value) sum_value
FROM v$waitstat, v$sysstat WHERE v$sysstat.name IN ('db block gets',
'consistent gets') group by v$waitstat.class, v$waitstat.count

18。查看sga情况
SELECT NAME, BYTES FROM SYS.V_$SGASTAT ORDER BY NAME ASC

19。查看catched object
SELECT owner, name, db_link, namespace,
type, sharable_mem, loads, executions,
locks, pins, kept FROM v$db_object_cache

20。查看V$SQLAREA
SELECT SQL_TEXT, SHARABLE_MEM, PERSISTENT_MEM, RUNTIME_MEM, SORTS,
VERSION_COUNT, LOADED_VERSIONS, OPEN_VERSIONS, USERS_OPENING, EXECUTIONS,
USERS_EXECUTING, LOADS, FIRST_LOAD_TIME, INVALIDATIONS, PARSE_CALLS, DISK_READS,
BUFFER_GETS, ROWS_PROCESSED FROM V$SQLAREA
21。查看object分类数量
select decode (o.type#,1,'INDEX' , 2,'TABLE' , 3 , 'CLUSTER' , 4, 'VIEW' , 5 ,
'SYNONYM' , 6 , 'SEQUENCE' , 'OTHER' ) object_type , count(*) quantity from
sys.obj$ o where o.type# > 1 group by decode (o.type#,1,'INDEX' , 2,'TABLE' , 3
, 'CLUSTER' , 4, 'VIEW' , 5 , 'SYNONYM' , 6 , 'SEQUENCE' , 'OTHER' ) union select
'COLUMN' , count(*) from sys.col$ union select 'DB LINK' , count(*) from

22。按用户查看object种类
select u.name schema, sum(decode(o.type#, 1, 1, NULL)) indexes,
sum(decode(o.type#, 2, 1, NULL)) tables, sum(decode(o.type#, 3, 1, NULL))
clusters, sum(decode(o.type#, 4, 1, NULL)) views, sum(decode(o.type#, 5, 1,
NULL)) synonyms, sum(decode(o.type#, 6, 1, NULL)) sequences,
sum(decode(o.type#, 1, NULL, 2, NULL, 3, NULL, 4, NULL, 5, NULL, 6, NULL, 1))
others from sys.obj$ o, sys.user$ u where o.type# >= 1 and u.user# =
o.owner# and u.name <> 'PUBLIC' group by u.name order by
sys.link$ union select 'CONSTRAINT' , count(*) from sys.con$

23。有关connection的相关信息
1）查看有哪些用户连接
select s.osuser os_user_name, decode(sign(48 - command), 1, to_char(command),
'Action Code #' || to_char(command) ) action, p.program oracle_process,
status session_status, s.terminal terminal, s.program program,
s.username user_name, s.fixed_table_sequence activity_meter, '' query,
0 memory, 0 max_memory, 0 cpu_usage, s.sid, s.serial# serial_num
from v$session s, v$process p where s.paddr=p.addr and s.type = 'USER'
order by s.username, s.osuser
2）根据v.sid查看对应连接的资源占用等情况
select n.name,
v.value,
n.class,
n.statistic#
from v$statname n,
v$sesstat v
where v.sid = 71 and
v.statistic# = n.statistic#
order by n.class, n.statistic#
3）根据sid查看对应连接正在运行的sql
select /*+ PUSH_SUBQ */
command_type,
sql_text,
sharable_mem,
persistent_mem,
runtime_mem,
sorts,
version_count,
loaded_versions,
open_versions,
users_opening,
executions,
users_executing,
loads,
first_load_time,
invalidations,
parse_calls,
disk_reads,
buffer_gets,
rows_processed,
sysdate start_time,
sysdate finish_time,
'>' || address sql_address,
'N' status
from v$sqlarea
where address = (select sql_address from v$session where sid = 71)

24．查询表空间使用情况select a.tablespace_name "表空间名称",
100-round((nvl(b.bytes_free,0)/a.bytes_alloc)*100,2) "占用率(%)",
round(a.bytes_alloc/1024/1024,2) "容量(M)",
round(nvl(b.bytes_free,0)/1024/1024,2) "空闲(M)",
round((a.bytes_alloc-nvl(b.bytes_free,0))/1024/1024,2) "使用(M)",
Largest "最大扩展段(M)",
to_char(sysdate,'yyyy-mm-dd hh24:mi:ss') "采样时间"
from (select f.tablespace_name,
sum(f.bytes) bytes_alloc,
sum(decode(f.autoextensible,'YES',f.maxbytes,'NO',f.bytes)) maxbytes
from dba_data_files f
group by tablespace_name) a,
(select f.tablespace_name,
sum(f.bytes) bytes_free
from dba_free_space f
group by tablespace_name) b,
(select round(max(ff.length)*16/1024,2) Largest,
ts.name tablespace_name
from sys.fet$ ff, sys.file$ tf,sys.ts$ ts
where ts.ts#=ff.ts# and ff.file#=tf.relfile# and ts.ts#=tf.ts#
group by ts.name, tf.blocks) c
where a.tablespace_name = b.tablespace_name and a.tablespace_name = c.tablespace_name

25. 查询表空间的碎片程度

select tablespace_name,count(tablespace_name) from dba_free_space group by tablespace_name
having count(tablespace_name)>10;

alter tablespace name coalesce;
alter table name deallocate unused;

create or replace view ts_blocks_v as
select tablespace_name,block_id,bytes,blocks,'free space' segment_name from dba_free_space
union all
select tablespace_name,block_id,bytes,blocks,segment_name from dba_extents;

select * from ts_blocks_v;

select tablespace_name,sum(bytes),max(bytes),count(block_id) from dba_free_space
group by tablespace_name;
 
 
26.监控索引是否使用
alter index &index_name monitoring usage;
alter index &index_name nomonitoring usage;
select * from v$object_usage where index_name = &index_name;
 
27.求数据文件的I/O分布
select df.name,phyrds,phywrts,phyblkrd,phyblkwrt,singleblkrds,readtim,writetim
  from v$filestat fs,v$dbfile df
where fs.file#=df.file# order by df.name;
 
28.求某个隐藏参数的值
  col ksppinm format a54
  col ksppstvl format a54
  select ksppinm, ksppstvl
   from x$ksppi pi, x$ksppcv cv
  where cv.indx=pi.indx and pi.ksppinm like '\_%' escape '\' and pi.ksppinm like '%&parameer%';
 
29.求系统中较大的latch
select name,sum(gets),sum(misses),sum(sleeps),sum(wait_time)
  from v$latch_children
group by name having sum(gets) > 50 order by 2;
 
30.求归档日志的切换频率(生产系统可能时间会很长)
select start_recid,start_time,end_recid,end_time,minutes from (select test.*, rownum as rn
  from (select b.recid start_recid,to_char(b.first_time,'yyyy-mm-dd hh24:mi:ss') start_time,
   a.recid end_recid,to_char(a.first_time,'yyyy-mm-dd hh24:mi:ss') end_time,round(((a.first_time-b.first_time)*24)*60,2) minutes
  from v$log_history a,v$log_history b where a.recid=b.recid+1 and b.first_time > sysdate -    order by a.first_time desc) test) y where y.rn < 30
31.求回滚段正在处理的事务
select a.name,b.xacts,c.sid,c.serial#,d.sql_text
  from v$rollname a,v$rollstat b,v$session c,v$sqltext d,v$transaction e
where a.usn=b.usn and b.usn=e.xidusn and c.taddr=e.addr
  and c.sql_address=d.address and c.sql_hash_value=d.hash_value order by a.name,c.sid,d.piece;
 
32.求出无效的对象
select 'alter procedure '||object_name||' compile;'
  from dba_objects
where status='INVALID' and owner='&' and object_type in ('PACKAGE','PACKAGE BODY');
/
select owner,object_name,object_type,status from dba_objects where status='INVALID';
 
--求process/session的状态
select p.pid,p.spid,s.program,s.sid,s.serial#
  from v$process p,v$session s where s.paddr=p.addr;
--求当前session的状态
select sn.name,ms.value
  from v$mystat ms,v$statname sn
where ms.statistic#=sn.statistic# and ms.value > 0;
--求表的索引信息
select ui.table_name,ui.index_name
  from user_indexes ui,user_ind_columns uic
where ui.table_name=uic.table_name and ui.index_name=uic.index_name
  and ui.table_name like '&table_name%' and uic.column_name='&column_name';
--显示表的外键信息
col search_condition format a54
select table_name,constraint_name
   from user_constraints
  where constraint_type ='R' and constraint_name in (select constraint_name from user_cons_columns where column_name='&1');
select rpad(child.table_name,25,' ') child_tablename,
  rpad(cp.column_name,17,' ') referring_column,rpad(parent.table_name,25,' ') parent_tablename,
  rpad(pc.column_name,15,' ') referred_column,rpad(child.constraint_name,25,' ') constraint_name
  from user_constraints child,user_constraints parent,
     user_cons_columns cp,user_cons_columns pc
where child.constraint_type = 'R' and child.r_constraint_name = parent.constraint_name and
   child.constraint_name = cp.constraint_name and parent.constraint_name = pc.constraint_name and
   cp.position = pc.position and child.table_name ='&table_name'
  order by child.owner,child.table_name,child.constraint_name,cp.position;
--显示表的分区及子分区(user_tab_subpartitions)
col table_name format a16
col partition_name format a16
col high_value format a81
select table_name,partition_name,HIGH_VALUE from user_tab_partitions where table_name='&table_name'
--使用dbms_xplan生成一个执行计划
explain plan set statement_id = '&sql_id' for &sql;
select * from table(dbms_xplan.display);
--求某个事务的重做信息(bytes)
select s.name,m.value
   from v$mystat m,v$statname s
  where m.statistic#=s.statistic# and s.name like '%redo size%';
--求cache中缓存超过其5%的对象
select o.owner,o.object_type,o.object_name,count(b.objd)
  from v$bh b,dba_objects o
where b.objd = o.object_id
  group by o.owner,o.object_type,o.object_name
  having count(b.objd) > (select to_number(value)*0.05 from v$parameter where name = 'db_block_buffers');
--求谁阻塞了某个session(10g)
select sid, username, event, blocking_session,
   seconds_in_wait, wait_time
  from v$session where state in ('WAITING') and wait_class != 'Idle';
--求session的OS进程ID
col program format a54
select p.spid "OS Thread", b.name "Name-User", s.program
  from v$process p, v$session s, v$bgprocess b
  where p.addr = s.paddr and p.addr = b.paddr
UNION ALL
select p.spid "OS Thread", s.username "Name-User", s.program
  from v$process p, v$session s where p.addr = s.paddr and s.username is not null;
--查会话的阻塞
col user_name format a32
select /*+ rule */ lpad(' ',decode(l.xidusn ,0,3,0))||l.oracle_username user_name, o.owner,o.object_name,s.sid,s.serial#
  from v$locked_object l,dba_objects o,v$session s
where l.object_id=o.object_id and l.session_id=s.sid order by o.object_id,xidusn desc ;
col username format a15
col lock_level format a8
col owner format a18
col object_name format a32
select /*+ rule */ s.username, decode(l.type,'tm','table lock', 'tx','row lock', null) lock_level, o.owner,o.object_name,s.sid,s.serial#
  from v$session s,v$lock l,dba_objects o
where l.sid = s.sid and l.id1 = o.object_id(+) and s.username is not null ;
--求等待的事件及会话信息/求会话的等待及会话信息
select se.sid,s.username,se.event,se.total_waits,se.time_waited,se.average_wait
   from v$session s,v$session_event se
where s.username is not null and se.sid=s.sid and s.status='ACTIVE' and se.event not like '%SQL*Net%' order by s.username;
select s.sid,s.username,sw.event,sw.wait_time,sw.state,sw.seconds_in_wait
   from v$session s,v$session_wait sw
where s.username is not null and sw.sid=s.sid and sw.event not like '%SQL*Net%' order by s.username;
--求会话等待的file_id/block_id
col event format a24
col p1text format a12
col p2text format a12
col p3text format a12
select sid,event,p1text, p1, p2text, p2, p3text, p3
   from v$session_wait
where event not like '%SQL%' and event not like '%rdbms%' and event not like '%mon%' order by event;
select name,wait_time from v$latch l where exists (select 1 from (select sid,event,p1text, p1, p2text, p2, p3text, p3
   from v$session_wait
where event not like '%SQL%' and event not like '%rdbms%' and event not like '%mon%'
) x where x.p1= l.latch#);
--求会话等待的对象
col owner format a18
col segment_name format a32
col segment_type format a32
select owner,segment_name,segment_type
   from dba_extents
where file_id = &file_id and &block_id between block_id and block_id + blocks - 1;
--求buffer cache中的块信息
select o.OBJECT_TYPE, substr(o.OBJECT_NAME,1,10) objname , b.objd , b.status, count(b.objd)
  from   v$bh b, dba_objects o
  where b.objd = o.data_object_id and o.owner = '&1' group by o.object_type, o.object_name,b.objd, b.status ;
--求日志文件的空间使用
select le.leseq current_log_sequence#, 100*cp.cpodr_bno/le.lesiz percentage_full
  from x$kcccp cp,x$kccle le
  where le.leseq =cp.cpodr_seq;
--求等待中的对象
　select /*+rule */ s.sid, s.username, w.event, o.owner, o.segment_name, o.segment_type,
       o.partition_name, w.seconds_in_wait seconds, w.state
   from v$session_wait w, v$session s, dba_extents o
  where w.event in (select name from v$event_name   where parameter1 = 'file#'
     and parameter2 = 'block#' and name not like 'control%')
     and o.owner <> 'sys' and w.sid = s.sid and w.p1 = o.file_id and w.p2 >= o.block_id and w.p2 < o.block_id + o.blocks
--求当前事务的重做尺寸
select value
   from v$mystat, v$statname
  where v$mystat.statistic# = v$statname.statistic# and v$statname.name = 'redo size';
--唤醒smon去清除临时段
column pid new_value Smon
set termout off
select p.pid from sys.v_$bgprocess b,sys.v_$process p where b.name = 'SMON' and p.addr = b.paddr
/
set termout on
oradebug wakeup &Smon
undefine Smon
--求回退率
select b.value/(a.value + b.value),a.value,b.value from v$sysstat a,v$sysstat b
where a.statistic#=4 and b.statistic#=5;
--求DISK READ较多的SQL
select st.sql_text from v$sql s,v$sqltext st
where s.address=st.address and s.hash_value=st.hash_value and s.disk_reads > 300;
--求DISK SORT严重的SQL
select sess.username, sql.sql_text, sort1.blocks
   from v$session sess, v$sqlarea sql, v$sort_usage sort1
  where sess.serial# = sort1.session_num
     and sort1.sqladdr = sql.address
     and sort1.sqlhash = sql.hash_value   and sort1.blocks > 200;
--求对象的创建代码
column column_name format a36
column sql_text format a99
select dbms_metadata.get_ddl('TABLE','&1') from dual;
select dbms_metadata.get_ddl('INDEX','&1') from dual;
--求表的索引
set linesize 131
select a.index_name,a.column_name,b.status, b.index_type
from user_ind_columns a,user_indexes b
where a.index_name=b.index_name and a.table_name='&1';
求索引中行数较多的
select index_name,blevel,num_rows,CLUSTERING_FACTOR,status from user_indexes where num_rows > 10000 and blevel > 0
select table_name,index_name,blevel,num_rows,CLUSTERING_FACTOR,status from user_indexes where status <> 'VALID'
--求当前会话的SID，SERIAL#
select sid, serial# from v$session where audsid = SYS_CONTEXT('USERENV','SESSIONID');
--求表空间的未用空间
col mbytes format 9999.9999
select tablespace_name,sum(bytes)/1024/1024 mbytes from dba_free_space group by tablespace_name;
--求表中定义的触发器
select table_name,index_type,index_name,uniqueness from user_indexes where table_name='&1';
select trigger_name from user_triggers where table_name='&1';
--求未定义索引的表
select table_name from user_tables where table_name not in (select table_name from user_ind_columns);
--执行常用的过程
exec print_sql('select count(*) from tab');
exec show_space2('table_name');
--求free memory
select * from v$sgastat where name='free memory';
select a.name,sum(b.value) from v$statname a,v$sesstat b where a.statistic# = b.statistic# group by a.name;
查看一下谁在使用那个可以得回滚段，或者查看一下某个可以得用户在使用回滚段，
找出领回滚段不断增长的事务，再看看如何处理它，是否可以将它commit，再不行
就看看能否kill它，等等, 查看当前正在使用的回滚段的用户信息和回滚段信息:
set linesize 121
SELECT r.name "ROLLBACK SEGMENT NAME ",l.sid "ORACLE PID",p.spid "SYSTEM PID ",s.username "ORACLE USERNAME"
FROM v$lock l, v$process p, v$rollname r, v$session s
WHERE l.sid = p.pid(+) AND s.sid=l.sid AND TRUNC(l.id1(+)/65536) = r.usn AND l.type(+) = 'TX' AND l.lmode(+) = 6 ORDER BY r.name;
--查看用户的回滚段的信息
select s.username, rn.name from v$session s, v$transaction t, v$rollstat r, v$rollname rn
where s.saddr = t.ses_addr and t.xidusn = r.usn and r.usn = rn.usn
--生成执行计划
explain plan set statement_id='a1' for &1;
--查看执行计划
select lpad(' ',2*(level-1))||operation operation,options,OBJECT_NAME,position from plan_table
start with id=0 and statement_id='a1' connect by prior id=parent_id and statement_id='a1'
--查看内存中存的使用
select decode(greatest(class,10),10,decode(class,1,'Data',2,'Sort',4,'Header',to_char(class)),'Rollback') "Class",
sum(decode(bitand(flag,1),1,0,1)) "Not Dirty",sum(decode(bitand(flag,1),1,1,0)) "Dirty",
sum(dirty_queue) "On Dirty",count(*) "Total"
from x$bh group by decode(greatest(class,10),10,decode(class,1,'Data',2,'Sort',4,'Header',to_char(class)),'Rollback');
-- 查看表空间状态
  select tablespace_name,extent_management,segment_space_management from dba_tablespaces;
  select table_name,freelists,freelist_groups from user_tables;
--查看系统请求情况
SELECT DECODE (name, 'summed dirty write queue length', value)/
DECODE (name, 'write requests', value) "Write Request Length"
FROM v$sysstat WHERE name IN ( 'summed dirty queue length', 'write requests') and value>0;
--计算data buffer 命中率
select a.value + b.value "logical_reads", c.value "phys_reads",
round(100 * ((a.value+b.value)-c.value) / (a.value+b.value)) "BUFFER HIT RATIO"
from v$sysstat a, v$sysstat b, v$sysstat c
where a.statistic# = 40 and b.statistic# = 41 and c.statistic# = 42;
SELECT name, (1-(physical_reads/(db_block_gets+consistent_gets)))*100 H_RATIO FROM v$buffer_pool_statistics;
--查看内存使用情况
select least(max(b.value)/(1024*1024),sum(a.bytes)/(1024*1024)) shared_pool_used,
max(b.value)/(1024*1024) shared_pool_size,greatest(max(b.value)/(1024*1024),sum(a.bytes)/(1024*1024))-
(sum(a.bytes)/(1024*1024)) shared_pool_avail,((sum(a.bytes)/(1024*1024))/(max(b.value)/(1024*1024)))*100 avail_pool_pct
from v$sgastat a, v$parameter b where (a.pool='shared pool' and a.name not in ('free memory')) and b.name='shared_pool_size';
--查看用户使用内存情况
select username, sum(sharable_mem), sum(persistent_mem), sum(runtime_mem)
from sys.v_$sqlarea a, dba_users b
where a.parsing_user_id = b.user_id group by username;
--查看对象的缓存情况
select OWNER,NAMESPACE,TYPE,NAME,SHARABLE_MEM,LOADS,EXECUTIONS,LOCKS,PINS,KEPT
from v$db_object_cache where type not in ('NOT LOADED','NON-EXISTENT','VIEW','TABLE','SEQUENCE')
and executions>0 and loads>1 and kept='NO' order by owner,namespace,type,executions desc;
select type,count(*) from v$db_object_cache group by type;
--查看库缓存命中率
select namespace,gets, gethitratio*100 gethitratio,pins,pinhitratio*100 pinhitratio,RELOADS,INVALIDATIONS from v$librarycache
--查看某些用户的hash
select a.username, count(b.hash_value) total_hash,count(b.hash_value)-count(unique(b.hash_value)) same_hash,
(count(unique(b.hash_value))/count(b.hash_value))*100 u_hash_ratio
from dba_users a, v$sqlarea b where a.user_id=b.parsing_user_id group by a.username;
--查看字典命中率
select (sum(getmisses)/sum(gets)) ratio from v$rowcache;
--查看undo段的使用情况
SELECT d.segment_name,extents,optsize,shrinks,aveshrink,aveactive,d.status
FROM v$rollname n,v$rollstat s,dba_rollback_segs d
WHERE d.segment_id=n.usn(+) and d.segment_id=s.usn(+);
--无效的对象
select owner,object_type,object_name from dba_objects where status='INVALID';
select constraint_name,table_name from dba_constraints where status='INVALID';
--求出某个进程，并对它进行跟踪
select s.sid,s.serial# from v$session s,v$process p where s.paddr=p.addr and p.spid=&1;
exec dbms_system.SET_SQL_TRACE_IN_SESSION(&1,&2,true);
exec dbms_system.SET_SQL_TRACE_IN_SESSION(&1,&2,false);
--求出锁定的对象
select do.object_name,session_id,process,locked_mode
from v$locked_object lo, dba_objects do where lo.object_id=do.object_id;
--求当前session的跟踪文件
SELECT p1.value || '/' || p2.value || '_ora_' || p.spid || '.ora' filename
   FROM v$process p, v$session s, v$parameter p1, v$parameter p2
  WHERE p1.name = 'user_dump_dest' AND p2.name = 'instance_name'
     AND p.addr = s.paddr AND s.audsid = USERENV('SESSIONID') AND p.background is null AND instr(p.program,'CJQ') = 0;
--求对象所在的文件及块号
select segment_name,header_file,header_block
from dba_segments where segment_name like '&1';
--求对象发生事务时回退段及块号
select a.segment_name,a.header_file,a.header_block
from dba_segments a,dba_rollback_segs b
where a.segment_name=b.segment_name and b.segment_id='&1'
--9i的在线重定义表
/*如果在线重定义的表没有主键需要创建主键*/
exec dbms_redefinition.can_redef_table('cybercafe','announcement');
create table anno2 as select * from announcement
exec dbms_redefinition.start_redef_table('cybercafe','announcement','anno2');
exec dbms_redefinition.sync_interim_table('cybercafe','announcement','anno2');
exec dbms_redefinition.finish_redef_table('cybercafe','announcement','anno2');
drop table anno2
exec dbms_redefinition.abort_redef_table('cybercafe','announcement','anno2');
--常用的logmnr脚本(cybercafe)
exec sys.dbms_logmnr_d.build(dictionary_filename =>'esal',dictionary_location =>'/home/oracle/logmnr');
exec sys.dbms_logmnr.add_logfile(logfilename=>'/home/oracle/oradata/esal/archive/1_24050.dbf', options=>sys.dbms_logmnr.new);
exec sys.dbms_logmnr.add_logfile(logfilename=>'/home/oracle/oradata/esal/archive/1_22912.dbf', options=>sys.dbms_logmnr.addfile);
exec sys.dbms_logmnr.add_logfile(logfilename=>'/home/oracle/oradata/esal/archive/1_22913.dbf', options=>sys.dbms_logmnr.addfile);
exec sys.dbms_logmnr.add_logfile(logfilename=>'/home/oracle/oradata/esal/archive/1_22914.dbf', options=>sys.dbms_logmnr.addfile);
exec sys.dbms_logmnr.start_logmnr(dictfilename=>'/home/oracle/logmnr/esal.ora');
create table logmnr2 as select * from v$logmnr_contents;
--与权限相关的字典
ALL_COL_PRIVS  表示列上的授权，用户和PUBLIC是被授予者
ALL_COL_PRIVS_MADE  表示列上的授权，用户是属主和被授予者
ALL_COL_RECD  表示列上的授权，用户和PUBLIC是被授予者
ALL_TAB_PRIVS  表示对象上的授权，用户是PUBLIC或被授予者或用户是属主
ALL_TAB_PRIVS_MADE   表示对象上的权限，用户是属主或授予者
ALL_TAB_PRIVS_RECD   表示对象上的权限, 用户是PUBLIC或被授予者
DBA_COL_PRIVS  数据库列上的所有授权
DBA_ROLE_PRIVS  显示已授予用户或其他角色的角色
DBA_SYS_PRIVS  已授予用户或角色的系统权限
DBA_TAB_PRIVS  数据库对象上的所有权限
ROLE_ROLE_PRIVS  显示已授予用户的角色
ROLE_SYS_PRIVS  显示通过角色授予用户的系统权限
ROLE_TAB_PRIVS  显示通过角色授予用户的对象权限
SESSION_PRIVS  显示用户现在可利用的所有系统权限
USER_COL_PRIVS  显示列上的权限，用户是属主、授予者或被授予者
USER_COL_PRIVS_MADE 显示列上已授予的权限，用户是属主或授予者
USER_COL_PRIVS_RECD 显示列上已授予的权限，用户是属主或被授予者
USER_ROLE_PRIVS  显示已授予给用户的所有角色
USER_SYS_PRIVS  显示已授予给用户的所有系统权限
USER_TAB_PRIVS  显示已授予给用户的所有对象权限
USER_TAB_PRIVS_MADE 显示已授予给其他用户的对象权限，用户是属主
USER_TAB_PRIVS_RECD 显示已授予给其他用户的对象权限，用户是被授予者
--如何用dbms_stats分析表及模式？
exec dbms_stats.gather_schema_stats(ownname=>'&USER_NAME',estimate_percent=>dbms_stats.auto_sample_size,
  method_opt => 'for all columns size auto',degree=> DBMS_STATS.DEFAULT_DEGREE);
exec dbms_stats.gather_schema_stats(ownname=>'&USER_NAME',estimate_percent=>dbms_stats.auto_sample_size


1.查询有enqueue等待的事件
SELECT b.SID, b.serial#, b.username, machine, event, wait_time,
CHR (BITAND (p1, -16777216) / 16777215)
|| CHR (BITAND (p1, 16711680) / 65535) "Enqueue Type"
FROM v$session_wait a, v$session b
WHERE a.event NOT LIKE 'SQL*N%'
AND a.event NOT LIKE 'rdbms%'
AND a.SID = b.SID
AND b.SID > 8
AND a.event = 'enqueue'
ORDER BY username;
2
如何确定哪个表空间读写频繁?
select name,phyrds,phywrts,readtim,writetim
from v$filestat a,v$dbfile b
where a.file# = b.file#
order by readtim desc
3
Library Cache Pin/Lock Pile Up 
SELECT s.sid, kglpnmod “Mode”, kglpnreq “Req”, SPID “OS Process”
FROM v$session_wait w, x$kglpn p, v$session s ,v$process o
WHERE p.kglpnuse=s.saddr
AND kglpnhdl=w.p1raw
and w.event like ‘%library cache pin%’
and s.paddr=o.addr
4全表扫描的表
SQL>col name for a30
SQL>select name,value from v$sysstat
2 where name in (’table scans(short tables)’,'table scans(long tables)');
5
查询SQL语句执行时,硬语法分析的次数
select name,value
from v$sysstat
where name like ‘parse count%’;
6
该项显示buffer cache大小是否合适。
公式：1-((physical reads-physical reads direct-physical reads direct (lob)) / session logical reads)
执行：
select 1-((a.value-b.value-c.value)/d.value)
from v$sysstat a,v$sysstat b,v$sysstat c,v$sysstat d
where a.name=’physical reads’ and
b.name=’physical reads direct’ and
c.name=’physical reads direct (lob)’ and
d.name=’session logical reads’;
7
该项显示buffer命中率。
公式：1-(physical reads/ (db block gets+consistent gets))
执行：
select 1 - (sum(decode(name, ‘physical reads’, value, 0)) /
(sum(decode(name, ‘db block gets’, value, 0)) +
sum(decode(name, ‘consistent gets’, value, 0))))
“Buffer Hit Ratio”
from v$sysstat;
8
Soft parse ratio：这项将显示系统是否有太多硬解析。该值将会与原始统计数据对比以确保精确。例如，软解析率仅为0.2则表示硬解析率太高。不过，如果总解析量(parse count total)偏低，这项值可以被忽略。
公式：1 - ( parse count (hard) / parse count (total) )
执行：
select 1-(a.value/b.value)
from v$sysstat a,v$sysstat b
Where a.name=’parse count (hard)’ and b.name=’parse count (total)’;
9
In-memory sort ratio：该项显示内存中完成的排序所占比例。最理想状态下，在OLTP系统中，大部分排序不仅小并且能够完全在内存里完成排序。
公式：sorts (memory) / ( sorts (memory) + sorts (disk) )
执行：
select a.value/(b.value+c.value)
from v$sysstat a,v$sysstat b,v$sysstat c
where a.name=’sorts (memory)’ and
b.name=’sorts (memory)’ and c.name=’sorts (disk)’;
10
Parse to execute ratio：在生产环境，最理想状态是一条sql语句一次解析多数运行。
公式：1 - (parse count/execute count)
执行：
select 1-(a.value/b.value)
from v$sysstat a,v$sysstat b
where a.name=’parse count (total)’ and b.name=’execute count’;
11
Parse CPU to total CPU ratio：该项显示总的CPU花费在执行及解析上的比率。如果这项比率较低，说明系统执行了太多的解析。
公式：1 - (parse time cpu / CPU used by this session)
执行：
select 1-(a.value/b.value)
from v$sysstat a,v$sysstat b
where a.name=’parse time cpu’ and
b.name=’CPU used by this session’;
12
Parse time CPU to parse time elapsed：通常，该项显示锁竞争比率。这项比率计算
是否时间花费在解析分配给CPU进行周期运算(即生产工作)。解析时间花费不在CPU周期运算通常表示由于锁竞争导致了时间花费
公式：parse time cpu / parse time elapsed
执行：
select a.value/b.value
from v$sysstat a,v$sysstat b
where a.name=’parse time cpu’ and b.name=’parse time elapsed’;
13
从V$SYSSTAT获取负载间档(Load Profile)数据
　　负载间档是监控系统吞吐量和负载变化的重要部分，该部分提供如下每秒和每个事务的统计信息：logons cumulative, parse count (total), parse count (hard), executes, physical reads, physical writes, block changes, and redo size.
　　被格式化的数据可检查’rates’是否过高，或用于对比其它基线数据设置为识别system profile在期间如何变化。例如，计算每个事务中block changes可用如下公式：
db block changes / ( user commits + user rollbacks )
执行：
select a.value/(b.value+c.value)
from v$sysstat a,v$sysstat b,v$sysstat c
where a.name=’db block changes’ and
b.name=’user commits’ and c.name=’user rollbacks’;
其它计算统计以衡量负载方式，如下：
l Blocks changed for each read：这项显示出block changes在block reads中的比例。它将指出是否系统主要用于只读访问或是主要进行诸多数据操作(如：inserts/updates/deletes)
公式：db block changes / session logical reads
执行：
select a.value/b.value
from v$sysstat a,v$sysstat b
where a.name=’db block changes’ and
b.name=’session logical reads’ ;
14
Rows for each sort：
公式：sorts (rows) / ( sorts (memory) + sorts (disk) )
执行：
select a.value/(b.value+c.value)
from v$sysstat a,v$sysstat b,v$sysstat c
where a.name=’sorts (rows)’ and
b.name=’sorts (memory)’ and c.name=’sorts (disk)’;
15
查看某表的约束条件
SQL>select constraint_name, constraint_type,search_condition, r_constraint_name
from user_constraints where table_name = upper(’&table_name’);
SQL>select c.constraint_name,c.constraint_type,cc.column_name
from user_constraints c,user_cons_columns cc
where c.owner = upper(’&table_owner’) and c.table_name = upper(’&table_name’)
and c.owner = cc.owner and c.constraint_name = cc.constraint_name
order by cc.position;
16
查看表空间的名称及大小
select t.tablespace_name, round(sum(bytes/(1024*1024)),0) ts_size
from dba_tablespaces t, dba_data_files d
where t.tablespace_name = d.tablespace_name
group by t.tablespace_name;
17
查看回滚段名称及大小
select segment_name, tablespace_name, r.status,
(initial_extent/1024) InitialExtent,(next_extent/1024) NextExtent,
max_extents, v.curext CurExtent
From dba_rollback_segs r, v$rollstat v
Where r.segment_id = v.usn(+)
order by segment_name ;
18
查看表空间的使用情况
select sum(bytes)/(1024*1024) as free_space,tablespace_name
from dba_free_space
group by tablespace_name;
SELECT A.TABLESPACE_NAME,A.BYTES TOTAL,B.BYTES USED, C.BYTES FREE,
(B.BYTES*100)/A.BYTES ”% USED”,(C.BYTES*100)/A.BYTES ”% FREE”
FROM SYS.SM$TS_AVAIL A,SYS.SM$TS_USED B,SYS.SM$TS_FREE C
WHERE A.TABLESPACE_NAME=B.TABLESPACE_NAME AND A.TABLESPACE_NAME=C.TABLESPACE_NAME;
19
当移动一个表的多个分区时的脚本
BEGIN
FOR x IN (SELECT partition_name
FROM user_tab_partitions
WHERE table_name = ‘BIG_TABLE2′)
LOOP
EXECUTE IMMEDIATE ‘alter table big_table2 move partition ‘
|| x.partition_name;
END LOOP;
END;
/
20
查看LOCK
SELECT /*+ ORDERED USE_HASH(H,R) */
H.SID HOLD_SID,
R.SID WAIT_SID,
decode(H.type,
”MR”, ”Media Recovery”,
”RT”, ”Redo Thread”,
”UN”, ”User Name”,
”TX”, ”Transaction”,
”TM”, ”DML”,
”UL”, ”PL/SQL User Lock”,
”DX”, ”Distributed Xaction”,
”CF”, ”Control File”,
”IS”, ”Instance State”,
”FS”, ”File Set”,
”IR”, ”Instance Recovery”,
”ST”, ”Disk Space Transaction”,
”TS”, ”Temp Segment”,
”IV”, ”Library Cache Invalidation”,
”LS”, ”Log Start or Switch”,
”RW”, ”Row Wait”,
”SQ”, ”Sequence Number”,
”TE”, ”Extend Table”,
”TT”, ”Temp Table”,
H.type) type,
decode(H.lmode,
0, ”None”, 1, ”Null”,
2, ”Row-S (SS)”, 3, ”Row-X (SX)”,
4, ”Share”, 5, ”S/Row-X (SSX)”,
6, ”Exclusive”, to_char(H.lmode)) hold,
decode(r.request, 0, ”None”,
1, ”Null”, 2, ”Row-S (SS)”,
3, ”Row-X (SX)”, 4, ”Share”,
5, ”S/Row-X (SSX)”,6, ”Exclusive”,
to_char(R.request)) request,
R.ID1,R.ID2,R.CTIME
FROM VLOCK H,VLOCK R
WHERE H.BLOCK = 1 AND R.BLOCK=0
and H.TYPE <> ”MR” AND R.TYPE <> ”MR”
AND H.ID1 = R.ID1 AND H.ID2 = R.ID2
21
查看ORACLE运行的OS平台
SQL> run
1 begin
2 dbms_output.put_line(
3 dbms_utility.port_string);
4* end;
Linuxi386/Linux-2.0.34-8.1.0
PL/SQL 过程已成功完成。
22
查看空间详细使用情况
CREATE OR REPLACE PROCEDURE show_space (
p_segname IN VARCHAR2,
p_owner IN VARCHAR2 DEFAULT USER,
p_type IN VARCHAR2 DEFAULT 'TABLE',
p_partition IN VARCHAR2 DEFAULT NULL
)
AS
l_total_blocks NUMBER;
l_total_bytes NUMBER;
l_unused_blocks NUMBER;
l_unused_bytes NUMBER;
l_lastusedextfileid NUMBER;
l_lastusedextblockid NUMBER;
l_last_used_block NUMBER;
PROCEDURE p (p_label IN VARCHAR2, p_num IN NUMBER)
IS
BEGIN
DBMS_OUTPUT.put_line (RPAD (p_label, 40, '.') || p_num);
END;
BEGIN
DBMS_SPACE.unused_space
(segment_owner => p_owner,
segment_name => p_segname,
segment_type => p_type,
partition_name => p_partition,
total_blocks => l_total_blocks,
total_bytes => l_total_bytes,
unused_blocks => l_unused_blocks,
unused_bytes => l_unused_bytes,
last_used_extent_file_id => l_lastusedextfileid,
last_used_extent_block_id => l_lastusedextblocki
last_used_block => l_last_used_block
);
p ('Total Blocks', l_total_blocks);
p ('Total Bytes', l_total_bytes);
p ('Unused Blocks', l_unused_blocks);
p ('Unused Bytes', l_unused_bytes);
p ('Last Used Ext FileId', l_lastusedextfileid);
p ('Last Used Ext BlockId', l_lastusedextblockid);
p ('Last Used Block', l_last_used_block);
END;
/
24
显示缓冲区的相关SQL
SELECT tch, file#, dbablk,
CASE
WHEN obj = 4294967295
THEN 'rbs/compat segment'
ELSE (SELECT MAX ( '('
|| object_type
|| ') '
|| owner
|| '.'
|| object_name
)
|| DECODE (COUNT (*), 1, '', ' maybe!')
FROM dba_objects
WHERE data_object_id = x.obj)
END what
FROM (SELECT tch, file#, dbablk, obj
FROM x$bh
WHERE state <> 0
ORDER BY tch DESC) x
WHERE ROWNUM <= 5;
25
获取生成的根据文件名
select c.value ||'/' || d.instance_name || '_ora_' ||a.spid || '.trc' trace 
from v$process a,v$session b,v$parameter c,v$instance d
where a.addr=b.paddr
and b.audsid=userenv('sessionid')
and c.name='user_dump_dest'
/
在v$session_longops视图中，sofar字段表示已经扫描的块数，totalwork表示总得需要扫描的块数，所以我们即可以对正在运行的长查询进行监控，比如在索引创建时，查看索引创建的进度，也可以查看系统中以往的长查询。。。
col opname format a32
col target_desc format a32
col perwork format a12
set lines 131
select sid,OPNAME,TARGET_DESC,sofar,TOTALWORK,trunc(sofar/totalwork*100,2)||'%' as perwork 
from v$session_longops where sofar!=totalwork;
set lines 121
set pages 999
col opname format a29
col target format a29
col target_desc format a12
col perwork format a12
col remain format 99
col start_time format a21
col sofar format 99999999
col totalwork format 99999999
col sql_text format a101
col bufgets format 99999999
select opname,target,to_char(start_time,'yy-mm-dd:hh24:mi:ss') start_time,elapsed_seconds elapsed,
executions execs,buffer_gets/decode(executions,0,1,executions) bufgets,module,sql_text
from v$session_longops sl,v$sqlarea sa
where sl.sql_hash_value = sa.hash_value and upper(substr(module,1,4)) <> 'RMAN' and substr(opname,1,4) <> 'RMAN' 
and module <> 'SQL*Plus' and sl.start_time>trunc(sysdate)
order by start_time;
1. 监控事例的等待 
select event,sum(decode(wait_Time,0,0,1)) "Prev", sum(decode(wait_Time,0,1,0)) "Curr",count(*) "Tot" 
from v$session_Wait group by event order by 4;
2. 回滚段的争用情况 
select name, waits, gets, waits/gets "Ratio" from v$rollstat a, v$rollname b where a.usn = b.usn;
3. 监控表空间的 I/O 比例 
select df.tablespace_name name,df.file_name "file",f.phyrds pyr, f.phyblkrd pbr,f.phywrts pyw, f.phyblkwrt pbw from v$filestat f, dba_data_files df where f.file# = df.file_id order by df.tablespace_name;
4. 监控文件系统的 I/O 比例 
select substr(a.file#,1,2) "#", substr(a.name,1,30) "Name", a.status, a.bytes, b.phyrds, b.phywrts from v$datafile a, v$filestat b where a.file# = b.file#;
5.在某个用户下找所有的索引 
select user_indexes.table_name, user_indexes.index_name,uniqueness, column_name from user_ind_columns, user_indexes where user_ind_columns.index_name = user_indexes.index_name and user_ind_columns.table_name = user_indexes.table_name order by user_indexes.table_type, user_indexes.table_name, user_indexes.index_name, column_position;
6. 监控 SGA 的命中率 
select a.value + b.value "logical_reads", c.value "phys_reads", round(100 * ((a.value+b.value)-c.value) / (a.value+b.value)) "BUFFER HIT RATIO" from v$sysstat a, v$sysstat b, v$sysstat c where a.statistic# = 38 and b.statistic# = 39 and c.statistic# = 40;
7. 监控 SGA 中字典缓冲区的命中率 
select parameter, gets,Getmisses , getmisses/(gets+getmisses)*100 "miss ratio", (1-(sum(getmisses)/ (sum(gets)+sum(getmisses))))*100 "Hit ratio" from v$rowcache where gets+getmisses <>0 group by parameter, gets, getmisses; 
8. 监控 SGA 中共享缓存区的命中率，应该小于1%
select sum(pins) "Total Pins", sum(reloads) "Total Reloads", sum(reloads)/sum(pins) *100 libcache from v$librarycache; select sum(pinhits-reloads)/sum(pins) "hit radio",sum(reloads)/sum(pins) "reload percent" from v$librarycache;9. 显示所有数据库对象的类别和大小 select count(name) num_instances ,type ,sum(source_size) source_size , sum(parsed_size) parsed_size ,sum(code_size) code_size ,sum(error_size) error_size, sum(source_size) +sum(parsed_size) +sum(code_size) +sum(error_size) size_required from dba_object_size group by type order by 2;
10. 监控 SGA 中重做日志缓存区的命中率，应该小于1% SELECT name, gets, misses, immediate_gets, immediate_misses, Decode(gets,0,0,misses/gets*100) ratio1, Decode(immediate_gets+immediate_misses,0,0, immediate_misses/(immediate_gets+immediate_misses)*100) ratio2 FROM v$latch WHERE name IN ('redo allocation', 'redo copy');
11. 监控内存和硬盘的排序比率，最好使它小于 .10，增加 sort_area_size 
SELECT name, value FROM v$sysstat WHERE name IN ('sorts (memory)', 'sorts (disk)');
12. 监控当前数据库谁在运行什么SQL语句 
SELECT osuser, username, sql_text from v$session a, v$sqltext b where a.sql_address =b.address order by address, piece;
13. 监控字典缓冲区 
SELECT (SUM(PINS - RELOADS)) / SUM(PINS) "LIB CACHE" FROM V$LIBRARYCACHE; SELECT (SUM(GETS - GETMISSES - USAGE - FIXED)) / SUM(GETS) "ROW CACHE" FROM V$ROWCACHE; SELECT SUM(PINS) "EXECUTIONS", SUM(RELOADS) "CACHE MISSES WHILE EXECUTING" FROM
V$LIBRARYCACHE; 后者除以前者,此比率小于1%,接近0%为好。 SELECT SUM(GETS) "DICTIONARY GETS",SUM(GETMISSES) "DICTIONARY CACHE GET MISSES" FROM V$ROWCACHE
14. 找ORACLE字符集 
select * from sys.props$ where name='NLS_CHARACTERSET'; 
15. 监控 MTS 
select busy/(busy+idle) "shared servers busy" from v$dispatcher; 此值大于0.5时，参数需加大 select sum(wait)/sum(totalq) "dispatcher waits" from v$queue where type='dispatcher'; select count(*) from v$dispatcher; select servers_highwater from v$mts; servers_highwater接近mts_max_servers时，参数需加大
16. 碎片程度 
select tablespace_name,count(tablespace_name) from dba_free_space group by tablespace_name having count(tablespace_name)>10; alter tablespace name coalesce; alter table name deallocate unused; create or replace view ts_blocks_v as select tablespace_name,block_id,bytes,blocks,'free space' segment_name from dba_free_space union all select tablespace_name,block_id,bytes,blocks,segment_name from dba_extents; select * from ts_blocks_v; select tablespace_name,sum(bytes),max(bytes),count(block_id) from dba_free_space group by tablespace_name; 查看碎片程度高的表 SELECT segment_name table_name , COUNT(*) extents FROM dba_segments WHERE owner NOT IN ('SYS', 'SYSTEM') GROUP BY segment_name HAVING COUNT(*) = (SELECT MAX( COUNT(*) ) FROM dba_segments GROUP BY segment_name);
17. 表、索引的存储情况检查 
select segment_name,sum(bytes),count(*) ext_quan from dba_extents where tablespace_name='&tablespace_name' and segment_type='TABLE' group by tablespace_name,segment_name; select segment_name,count(*) from dba_extents where segment_type='INDEX' and owner='&owner' group by segment_name;18、找使用CPU多的用户session 12是cpu used by this session select a.sid,spid,status,substr(a.program,1,40) prog,a.terminal,osuser,value/60/100 value from v$session a,v$process b,v$sesstat c where c.statistic#=12 and c.sid=a.sid and a.paddr=b.addr order by value desc;
寻找CPU使用过量的session ，找出高CPU利用率的SQL：
SELECT /*+ ORDERED */
sql_text
FROM v$sqltext a
WHERE (a.hash_value, a.address) IN
(SELECT decode(sql_hash_value, 0, prev_hash_value, sql_hash_value), decode(sql_hash_value, 0, prev_sql_addr, sql_address)
FROM v$session b
WHERE b.paddr = (SELECT addr
FROM v$process c
WHERE c.spid = '&pid'))
ORDER BY piece ASC;
[@more@]
