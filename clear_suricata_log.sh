#!/bin/bash
truncate -s 0 /var/log/suricata/*.json
truncate -s 0 /var/log/suricata/*.log
systemctl reload suricata > /dev/null 2>&1 || true
