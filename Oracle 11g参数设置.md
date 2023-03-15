一.19c單機安裝：

#!/bin/bash

##需要7.0+ 版本的Linux
#關閉selinux
```sql
sed -i 's\SELINUX=enforcing\SELINUX=disabled\' /etc/selinux/config
setenforce 0
```
#關閉防火牆
```sql
systemctl stop firewalld
systemctl disable firewalld
```
#禁用avahi-daemon
```sql
systemctl stop avahi-daemon
systemctl disable avahi-daemon
systemctl status avahi-daemon
```
#關閉NetworkManager
```sql
systemctl stop NetworkManager
systemctl disable NetworkManager
```

#設置RemoveIPC=false
```sql
echo "RemoveIPC=no" >> /etc/systemd/logind.conf
```

#配置/etc/hosts文件添加
```sql
cat >> /etc/hosts<<EOF

192.168.10.30 19c

EOF
```
#增大共享內存
```sql
#mount -t tmpfs shmfs -o size=7g /dev/shm
#echo 'shmfs /dev/shm tmpfs size=24g' >> /etc/fstab
```

#添加組
```sql
groupadd -g 1200 oinstall
groupadd -g 1201 dba
groupadd -g 1202 oper
groupadd -g 1203 backupdba
groupadd -g 1204 dgdba
groupadd -g 1205 kmdba
```

#添加用戶
```sql
useradd -m -d /home/oracle -u 1101 -g oinstall -G dba,oper,backupdba,dgdba,kmdba oracle
echo 'oracle' | passwd --stdin oracle
```

#創建安裝目錄
```sql
mkdir -p /u01/app/oracle/product/19c/dbhome_1
mkdir -p /u01/app/oraInventory
```
#更改目錄權限
```sql
chown -R oracle:oinstall /u01/app/oracle
chown -R oracle:oinstall /u01/app/oraInventory
chmod -R 775 /u01
```
#改變內核參數
```sql
cat >> /etc/sysctl.conf<<EOF

#Kernel for Oracle 19c

fs.aio-max-nr = 1048576
fs.file-max = 6815744
#kernel.shmall = 2097152
#kernel.shmmax = 4294967295
kernel.shmall = 16097152
kernel.shmmax = 128849018880
kernel.shmmni = 4096
kernel.sem = 250 32000 100 128
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576

EOF
```
#使內核參數立即生效
sysctl -p

#添加用戶資源限制
cat >> /etc/security/limits.conf<<EOF
```sql
#limits for Oracle users

oracle soft nproc 2047
oracle hard nproc 16384
oracle soft nofile 1024
oracle hard nofile 65536
oracle soft stack 10240
oracle hard stack 32768
oracle hard memlock 3145728
oracle soft memlock 3145728

 EOF
```
#編輯配置文件
cat >> /etc/profile<<EOF
```sql
#this is for oracle user
if [ \$USER = "oracle" ]; then
if [ \$SHELL = "/bin/ksh" ]; then
ulimit -p 16384
ulimit -n 65536
else
ulimit -u 16384 -n 65536
fi
umask 022
fi
EOF

```
#編輯登陸配置文件
  ```sql
cat >> /etc/pam.d/login<<EOF
#this is for oracle user
session required pam_limits.so
EOF
```

#為oracle用戶添加環境變量
  ```sql
cat >> /home/oracle/.bash_profile<<EOF
export ORACLE_BASE=/u01/app/oracle
export ORACLE_SID=19c
export ORACLE_HOME=/u01/app/oracle/product/19c/dbhome_1
export PATH=\$ORACLE_HOME/bin:\$PATH
export LD_LIBRARY_PATH=\$ORACLE_HOME/lib:\$LD_LIBRARY_PATH
EOF
source /home/oracle/.bash_profile
```
#關閉ntpd服務
```sql
/sbin/service ntpd stop
chkconfig ntpd off
mv /etc/ntp.conf /etc/ntp.conf.org
```
systemctl stop chronyd
systemctl disable chrnyd

version=`cat /etc/redhat-release | cut -d ' ' -f 7 | cut -d . -f 1`
```
#配置yum倉庫
 ```sql
mount /dev/cdrom /mnt

rm -f /etc/yum.repos.d/*
if [ $version=7 ] ; then
cat > /etc/yum.repos.d/rhel-debuginfo.repo<<EOF
[rhel-debuginfo]
name=Red Hat Enterprise Linux \$releasever - \$basearch - Debug
baseurl=file:///mnt/
enabled=1
gpgcheck=0
EOF
fi
```

#安裝oracle所需要的包
  ```sql
yum clean all

yum install -y gcc bc binutils compat-libcap1 compat-libstdc++ elfutils-libelf elfutils-libelf-devel fontconfig-devel glibc glibc-devel ksh libaio libaio-devel libX11 libXau libXi libXtst libXrender libXrender-devel libgcc libstdc++ libstdc++-devel libxcb make net-tools nfs-utils python python-configshell python-rtslib python-six targetcli smartmontools sysstat
  ```
