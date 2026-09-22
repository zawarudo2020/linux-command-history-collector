#!/bin/bash
yum install -y audit audit-libs
systemctl enable auditd
systemctl start auditd
cat >> /etc/audit/rules.d/audit.rules << 'EOF'
-a always,exit -F arch=b64 -S execve -k cmdlog
-a always,exit -F arch=b32 -S execve -k cmdlog
-a always,exclude -F gid=wazuh
-a always,exclude -F gid=zabbix
EOF
service auditd restart
