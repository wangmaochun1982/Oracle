
#1.进程及会话数(默认150)
```sql
--查看进程及会话数 
show parameter process; 
show parameter sessions; 
--修改进程及会话数 
alter system set processes=1200 scope=spfile;  
alter system set sessions=1325 scope=spfile;  
```
參考：sessions = 1.1 * processes + 5

#2.游標數

```sql
--查看游标数 
show parameter open_cursors; 
--查看当前打开的游标数目 
select count(*) from v$open_cursor; 
--修改最大游标数 
alter system set open_cursors=1000 scope=both 
```
