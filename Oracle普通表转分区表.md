
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
 
