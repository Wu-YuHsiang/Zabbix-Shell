#!/bin/bash
###如果要更新BASE檔，請到Proxy執行
###【例如:salt 049*app* cmd.script "salt://scripts/config_base/config_base.sh"】建議不要大量Host執行，會容易失敗
###從Proxy下載base檔
rm -rf /tmp/$(hostname)/base
mkdir -p /tmp/$(hostname)/base
curl -s http://104.155.239.122:8943/config_base/`hostname`.tar.gz -o "/tmp/`hostname`/`hostname`.tar.gz"
tar -C /tmp/`hostname`/base/ -zvxf /tmp/`hostname`/`hostname`.tar.gz
###執行比對Config檔
rm -rf /tmp/$(hostname)/local
###製作List檔案
ls -ll /opt/APP/openresty/nginx/conf/vhost/ | awk {'print $9'} | sed '/^$/d' | grep -v 'old\|bak\|bk' > /tmp/$(hostname)/list.txt
###複製Conf檔至tmp做比對
mkdir -p /tmp/$(hostname)/local
cp /opt/APP/openresty/nginx/conf/vhost/* /tmp/$(hostname)/local/
###ZBX變數
salt_minion=$(cat /etc/salt/minion_id)
agent_hostname=$(cat /etc/zabbix/zabbix_agentd.conf | grep -e Hostname=.* | awk -F'=' '{print $2}')
###比對迴圈
rm -rf /tmp/$(hostname)/check.txt
echo $RESULT
for CHECK in `cat /tmp/$(hostname)/list.txt`;
  do
    SDIFF=$(sdiff -E -b -i -s /tmp/$(hostname)/base/$CHECK /tmp/$(hostname)/local/$CHECK)
    sdiff -E -b -i -s /tmp/$(hostname)/base/$CHECK /tmp/$(hostname)/local/$CHECK
  if [ $? = 1 ]; then
    echo $CHECK$SDIFF > /tmp/$(hostname)/check.txt
  fi
done
RESULT=$(cat /tmp/$(hostname)/check.txt | wc -l)
END=$(cat /tmp/$(hostname)/check.txt)
BASE_COUNT=$(ls -ll /tmp/`hostname`/base/ | grep -v total | wc -l)
LOCAL_COUNT=$(ls -llh /tmp/`hostname`/local | grep -v total | wc -l)
if [[ $RESULT > 0 && $BASE_COUNT -ne $LOCAL_COUNT ]]; then
  /usr/bin/zabbix_sender -z 104.155.239.122 -p 10051 -s "$agent_hostname" -k config_vhost_check -o "$END" --tls-connect psk --tls-psk-identity "PSK 001" --tls-psk-file /etc/zabbix/zabbix_agentd.psk
  /usr/bin/zabbix_sender -z 104.155.239.122 -p 10051 -s "$agent_hostname" -k config_vhost_check -o "$BASE_COUNT"_notmatch_"$LOCAL_COUNT" --tls-connect psk --tls-psk-identity "PSK 001" --tls-psk-file /etc/zabbix/zabbix_agentd.psk
elif [[ $RESULT > 0 ]]; then
    /usr/bin/zabbix_sender -z 104.155.239.122 -p 10051 -s "$agent_hostname" -k config_vhost_check -o "$END" --tls-connect psk --tls-psk-identity "PSK 001" --tls-psk-file /etc/zabbix/zabbix_agentd.psk
elif [[ $BASE_COUNT -ne $LOCAL_COUNT ]]; then
  /usr/bin/zabbix_sender -z 104.155.239.122 -p 10051 -s "$agent_hostname" -k config_vhost_check -o "$BASE_COUNT"_notmatch_"$LOCAL_COUNT" --tls-connect psk --tls-psk-identity "PSK 001" --tls-psk-file /etc/zabbix/zabbix_agentd.psk
else
  /usr/bin/zabbix_sender -z 104.155.239.122 -p 10051 -s "$agent_hostname" -k config_vhost_check -o sucess  --tls-connect psk --tls-psk-identity "PSK 001" --tls-psk-file /etc/zabbix/zabbix_agentd.psk
fi
