#!/bin/bash
yum install -y audit audit-libs
systemctl enable auditd
systemctl start auditd
cat >> /etc/audit/rules.d/audit.rules << 'EOF'
-a never,exit -F arch=b64 -S execve -F gid=wazuh
-a never,exit -F arch=b32 -S execve -F gid=wazuh
-a never,exit -F arch=b64 -S execve -F gid=zabbix
-a never,exit -F arch=b32 -S execve -F gid=zabbix
-a always,exclude -F gid=wazuh
-a always,exclude -F gid=zabbix
-a always,exit -F arch=b64 -S execve -k cmdlog
-a always,exit -F arch=b32 -S execve -k cmdlog
EOF
mkdir /opt/logs/audit
cp /etc/audit/auditd.conf /etc/audit/auditd.conf.bak
sed -i \
  -e 's/^max_log_file[[:space:]]*=.*/max_log_file = 1024/' \
  -e 's/^num_logs[[:space:]]*=.*/num_logs = 10/' \
  /etc/audit/auditd.conf
service auditd restart
