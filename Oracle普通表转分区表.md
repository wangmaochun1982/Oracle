
<h1>A. Export/import method</h1>

<h3>1) Export your table:</h3>

```javascript
$ exp <user_name>/<pwd> tables=TEST_TABLE1 file=exp.dmp

```

<h3>2) Drop the table:</h3>

```javascript
SQL> drop table TEST_TABLE1;
```

<h3>3) Recreate the table with partitions:</h3>

```sql
SQL> create table TEST_TABLE1 (qty number(3), name varchar2(15)) partition by range (qty)(partition p1 values less than (501),
partition p2 values less than (maxvalue));
```

<h3>4) Import the table with ignore=y:</h3>

```sql
$ imp <user_name>/<pwd> file=exp.dmp ignore=y
```

The ignore=y causes the import to skip the table creation and continues to load all rows.

With Data Pump export/import (expdp/impdp) you can use the  table_exists_action option of impdp e.g. table_exists_action = APPEND or table_exists_action = REPLACE.



<h1>B. Insert with a subquery method</h1>

<h3>1.创建分区表</h3>

-- Create table 创建分区表T_PART,分区从14年6月开始。

```sql
create table T_PART
(
……
)
partition by range(time_stamp)(
  partition P20140601 values less than (TO_DATE(' 2014-06-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN'))
    tablespace DBS_D_JINGYU
);
```
 使用分区添加工具添加到15年6月份。

<h3>2.设置新建分区表为nologging， 重命名原表T为T_OLD</h3>

```sql
alter table t_part nologging;

rename T to T_old;
```

<h3>3.并行直接路径插入</h3>

```sql
alter session enable parallel dml;

insert /*+ append parallel(p,10) */ into t_part p select /*+ parallel(n,10) */ * from T_old n;

commit;

查看下insert的执行计划，确定都能用到并行度。

explain plan for insert /*+ append parallel(p,10) */ into t_part p select /*+ parallel(n,10) */ * from T_old n;

执行插入脚本

SQL> @/home/oracle/insert

~~~~~~~~~~~~~~~~~~~~~~~~~

已创建908792694行。

已用时间:  02: 09: 37.94

提交完成。

已用时间:  00: 08: 13.76
```

<h3>4.为分区表建立索引</h3>

<h4>4.1 重命名历史表的索引名</h4>

```sql
alter index PK_T rename to PK_T_bak;
alter table T_old rename constraint PK_T to PK_T_bak;
alter index IDX_T_2 rename to IDX_T_2_bak;
alter index IDX_T_3 rename to IDX_T_3_bak;
```

<h4>4.2 给新分区表T_PART创建主键及索引</h4>

```sql
create unique index PK_T on T_PART(OID, TIME_STAMP, SERIAL_NO, CITY_ID) local tablespace DBS_I_JINGYU nologging parallel 32;
索引已创建。
已用时间:  04: 39: 53.10
alter table T_PART add constraint PK_T primary key (OID, TIME_STAMP, SERIAL_NO, CITY_ID);
表已更改。
已用时间:  00: 00: 00.43


create index IDX_T_2 on T_PART (TIME_STAMP, SERIAL_NO, CITY_ID) local tablespace DBS_I_JINGYU nologging parallel 32;
索引已创建。
已用时间:  02: 27: 49.92
create index IDX_T_3 on T_PART (TIME_STAMP, CITY_ID) local tablespace DBS_I_JINGYU nologging parallel 32;
索引已创建。
已用时间:  02: 19: 06.74
```

<h4>4.3 修改索引和表为logging，noparallel</h4>

```sql
alter index PK_T logging noparallel;
alter index IDX_T_2 logging noparallel;
alter index IDX_T_3 logging noparallel;
alter table T_PART logging;
```

<h4>4.4 遇到的问题</h4>

建立唯一性索引时报错

```sql
SQL> create unique index PK_T on T_PART(OID, TIME_STAMP, SERIAL_NO, CITY_ID) local tablespace dbs_i_jingyu nologging parallel 32;

create unique index PK_T on T_PART(OID, TIME_STAMP, SERIAL_NO, CITY_ID) local tablespace dbs_i_jingyu nologging parallel 32

ORA-12801: 并行查询服务器 P000 中发出错误信号

ORA-01652: 无法通过 128 (在表空间 TMP 中) 扩展 temp 段
```

解决方式：增加临时表空间大小


```sql
alter tablespace TMP add tempfile '/usr3/oradata2/sysdata/tmp02.dbf' size 30G;

alter tablespace TMP add tempfile '/usr3/oradata2/sysdata/tmp03.dbf' size 30G;

alter tablespace TMP add tempfile '/usr3/oradata2/sysdata/tmp04.dbf' size 30G;
```

<h3>5.rename表，恢复T表的相关应用</h3>

rename T_PART为T，恢复T表应用。

```sql
rename T_PART to T;
```

根据实际情况决定是否彻底drop掉T_OLD，释放空间。


```sql
drop table T_OLD purge;
```
