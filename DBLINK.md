-- 关于 dblink 的问题
-- 授权某个用户具有管理dblink的权限
grant create public database link, create database link to xxx;
-- 所有dblink
select * from dba_db_links;
create database link dsdblink connect to xxx identified by xxx using 'orcl';
create database link DSDBLINK connect to xxx identified by xxx using ' 
(DESCRIPTION =
    (ADDRESS_LIST =
      (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.77.1)(PORT = 1521))
    )从
    (CONNECT_DATA =
      (SID = orcl)
      (SERVER = DEDICATED)
    )
)';
drop database link dsdblink;
drop public database link dsdblink;
