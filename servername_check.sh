
hostname=`hostname`

services=$(echo $hostname | awk -F\- '{print $1}')
rp=$(echo $hostname | awk -F\- '{print $2}')

change_servername=$(cat /root/rp_servername.txt | grep "$rp-$services")
if [[ ! -z $change_servername ]]; then
	for servername in $change_servername; do
		new_servername=$(echo $servername | awk -F\- '{print $3}')

    check_servername=`cat /opt/APP/openresty/nginx/conf/vhost/*.conf | grep server_name | grep -v "#server_name" | sed "s/ /\n/g" | sed '/^\s*$/d' | sed "s/;//g" | grep -v server_name | sort -n | uniq | grep $new_servername`
    if [[ ! -z $check_servername ]]; then
      echo -e "\033[43;37m $new_servername OK  \033[0m"
    else
      echo -e "\033[43;37m  $new_servername ERROR \033[0m"
    fi
	done
else
	echo -e "\033[43;37m New servername ERROR \033[0m"
	exit
fi

