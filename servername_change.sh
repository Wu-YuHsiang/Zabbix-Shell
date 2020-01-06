if [[ -z $1 ]]; then
	echo "請輸入品牌代號"
	exit
fi

if [[ -z $2 ]]; then
	echo "請輸入服務代號"
	exit
fi

rp=$1
services=$2

#新舊域名替換, 目前用置換域名方式 ex:030-fe-new-old
change_servername=$(cat /root/rp_servername.txt | grep "$rp-$services")
if [[ ! -z $change_servername ]]; then
	for servername in $change_servername; do
		new_servername=$(echo $servername | awk -F\- '{print $3}')
		old_servername=$(echo $servername | awk -F\- '{print $4}')

		sed -i "s/$old_servername/$new_servername/g" /opt/APP/openresty/nginx/conf/vhost/*.conf

		echo -e "\033[43;37m $old_servername ==> $new_servername\033[0m"
	done
else
	echo -e "\033[41;37m servername error please check!!\033[0m"
	exit
fi

systemctl enable salt-minion.service

cat /etc/salt/minion_id
systemctl restart salt-minion

systemctl stop nginx &&
	systemctl start nginx &&
	nginx -t
