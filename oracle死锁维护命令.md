1、死锁查询语句
```sql
SELECT    bs.username "Blocking User", bs.username "DB User",
          ws.username "Waiting User", bs.SID "SID", ws.SID "WSID",
          bs.serial# "Serial#", bs.sql_address "address",
          bs.sql_hash_value "Sql hash", bs.program "Blocking App",
          ws.program "Waiting App", bs.machine "Blocking Machine",
          ws.machine "Waiting Machine", bs.osuser "Blocking OS User",
          ws.osuser "Waiting OS User", bs.serial# "Serial#",
          ws.serial# "WSerial#",
          DECODE (wk.TYPE,
                  'MR', 'Media Recovery',
                  'RT', 'Redo Thread',
                  'UN', 'USER Name',
                  'TX', 'Transaction',
                  'TM', 'DML',
                  'UL', 'PL/SQL USER LOCK',
                  'DX', 'Distributed Xaction',
                  'CF', 'Control FILE',
                  'IS', 'Instance State',
                  'FS', 'FILE SET',
                  'IR', 'Instance Recovery',
                  'ST', 'Disk SPACE Transaction',
                  'TS', 'Temp Segment',
                  'IV', 'Library Cache Invalidation',
                  'LS', 'LOG START OR Switch',
                  'RW', 'ROW Wait',
                  'SQ', 'Sequence Number',
                  'TE', 'Extend TABLE',
                  'TT', 'Temp TABLE',
                  wk.TYPE
                 ) lock_type,
          DECODE (hk.lmode,
                  0, 'None',
                  1, 'NULL',
                  2, 'ROW-S (SS)',
                  3, 'ROW-X (SX)',
                  4, 'SHARE',
                  5, 'S/ROW-X (SSX)',
                  6, 'EXCLUSIVE',
                  TO_CHAR (hk.lmode)
                 ) mode_held,
          DECODE (wk.request,
                  0, 'None',
                  1, 'NULL',
                  2, 'ROW-S (SS)',
                  3, 'ROW-X (SX)',
                  4, 'SHARE',
                  5, 'S/ROW-X (SSX)',
                  6, 'EXCLUSIVE',
                  TO_CHAR (wk.request)
                 ) mode_requested,
          TO_CHAR (hk.id1) lock_id1, TO_CHAR (hk.id2) lock_id2,
          DECODE
             (hk.BLOCK,
              0, 'NOT Blocking',          /**//* Not blocking any other processes */
              1, 'Blocking',              /**//* This lock blocks other processes */
              2, 'Global',           /**//* This lock is global, so we can't tell */
              TO_CHAR (hk.BLOCK)
             ) blocking_others
     FROM v$lock hk, v$session bs, v$lock wk, v$session ws
    WHERE hk.BLOCK = 1
      AND hk.lmode != 0
      AND hk.lmode != 1
      AND wk.request != 0
      AND wk.TYPE(+) = hk.TYPE
      AND wk.id1(+) = hk.id1
      AND wk.id2(+) = hk.id2
      AND hk.SID = bs.SID(+)
      AND wk.SID = ws.SID(+)
      AND (bs.username IS NOT NULL)
      AND (bs.username <> 'SYSTEM')
      AND (bs.username <> 'SYS')
ORDER BY 1;
```

查询发生死锁的select语句

```sql
select sql_text from v$sql where hash_value in (
    select sql_hash_value from v$session where sid in (select session_id from v$locked_object)
)

```
检查数据库确定 是否 真实存在死锁，若有 哪台机器哪个程序。
```sql
select username,lockwait,status,machine,program from v$session where sid 
in (select session_id from v$locked_object)

如果有输出的结果，则说明有死锁，且能看到死锁的机器是哪一台。字段说明：
Username：死锁语句所用的数据库用户；
Lockwait：死锁的状态，如果有内容表示被死锁。
Status： 状态，active表示被死锁
Machine： 死锁语句所在的机器。
Program： 产生死锁的语句主要来自哪个应用程序。
```

查找死锁的进程：
```sql
SELECT s.username,
       l.OBJECT_ID,
       l.SESSION_ID,
       s.SERIAL#,
       l.ORACLE_USERNAME,
       l.OS_USER_NAME,
       l.PROCESS
  FROM V$LOCKED_OBJECT l, V$SESSION S
 WHERE l.SESSION_ID = S.SID;


```

kill掉这个死锁的进程：
```sql
alter system kill session ‘sid,serial#’; （其中sid=l.session_id）
```
kill掉这个Oracle进程
```sql
  select pro.spid from v$session ses, v$process pro where ses.sid=XX and ses.paddr=pro.addr;
```


