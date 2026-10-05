#!/bin/bash
yum install -y audit audit-libs
systemctl enable auditd
systemctl start auditd
cd /etc/audit/rules.d/
mkdir -p /etc/audit/audit-backup && cp -a /etc/audit/rules.d/* /etc/audit/audit-backup/ && rm -f /etc/audit/rules.d/*.rules

# 00:載入選項,錯誤行跳過不中斷
cat > 00-options.rules <<'EOF'
## 遇到錯誤的規則直接跳過,繼續載入後面的規則
-i
EOF

# 10:基本設定
cat > 10-base.rules <<'EOF'
## 清空現有規則
-D
## 核心佇列大小
-b 65536
## 失敗模式:1=printk
-f 1
## 佇列滿時等待時間
--backlog_wait_time 0
EOF

# 20:Wazuh 4.3 以後(群組 wazuh)
cat > 20-exclude-wazuh.rules <<'EOF'
-a never,exit -F arch=b64 -S execve -F gid=wazuh
-a never,exit -F arch=b32 -S execve -F gid=wazuh
EOF

# 21:Wazuh 4.3 以前(群組 ossec)
cat > 21-exclude-ossec.rules <<'EOF'
-a never,exit -F arch=b64 -S execve -F gid=ossec
-a never,exit -F arch=b32 -S execve -F gid=ossec
EOF

# 22:Zabbix
cat > 22-exclude-zabbix.rules <<'EOF'
-a never,exit -F arch=b64 -S execve -F gid=zabbix
-a never,exit -F arch=b32 -S execve -F gid=zabbix
EOF

# 50:指令記錄
cat > 50-cmdlog.rules <<'EOF'
-a always,exit -F arch=b64 -S execve -k cmdlog
-a always,exit -F arch=b32 -S execve -k cmdlog
EOF


# 建立日誌目錄並修復權限
LOG_DIR="/opt/logs/audit"
mkdir -p "$LOG_DIR"
chmod 700 "$LOG_DIR"
chown root:root "$LOG_DIR"

cp /etc/audit/auditd.conf /etc/audit/auditd.conf.bak
sed -i \
  -e 's/^max_log_file[[:space:]]*=.*/max_log_file = 1024/' \
  -e 's/^num_logs[[:space:]]*=.*/num_logs = 10/' \
  -e "s|^log_file[[:space:]]*=.*|log_file = /opt/logs/audit/audit.log|" \
  /etc/audit/auditd.conf
service auditd restart
