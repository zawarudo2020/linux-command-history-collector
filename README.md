curl -o /etc/profile.d/history.sh https://raw.githubusercontent.com/zawarudo2020/linux-command-history-collector/main/history.sh

chmod +x /etc/profile.d/history.sh
> /var/log/.histlog

chmod 666 /var/log/.histlog

寫入到 /var/ossec/etc/decoders/local_decoder.xml
注意if the log is Syslog-like, then prematch only analyzes the log after the Syslog-like header. If the log is not Syslog-like, then it analyzes the entire log.
Taken from here: https://documentation.wazuh.com/current/user-manual/ruleset/ruleset-xml-syntax/decoders.html#decoders-prematch
如果日誌開頭太像syslog，prematch可能會出錯

<decoder name="danny-custom-shell-log">
  <prematch>USER=</prematch>
</decoder>

<decoder name="danny-custom-shell-log-details">
  <parent>danny-custom-shell-log</parent>
  <regex type="pcre2">USER=(.*?) ; TTY=(.*?) ; LOGIN_IP=(.*?) ; PWD=(.*?) ; COMMAND=(.*?) ; PROCESS=(.*?) ; PID=(.*?) ;</regex>
  <order>user, tty, srcip, pwd, command, process, pid</order>
</decoder>

寫入到/var/osssec/etc/shared/default/agent.conf
<ossec_config>
  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/.histlog</location>
  </localfile>
</ossec_config>

寫入到var/ossec/etc/rules/local_rules.xml
<group name="command history">
<rule id="100001" level="10">
  <decoded_as>danny-custom-shell-log</decoded_as>
  <description>command history</description>
</rule>
</group>
