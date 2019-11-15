#!/bin/bash
# 自动添加网卡链接聚合规则
# yin 2019-11-15
# 一键添加 activebackup loadbalence roundrobin


# 使用nmcli命令进行创建，所以需要开启NetwrokManager服务
function netwrok_manager_server() {
commd=$(systemctl status NetworkManager |grep -o "running")

if [ -z ${commd} ];then
	echo -e "\033[32m starting NetworkManager Service ...."
	sleep 3
	systemctl start NetworkManager >/dev/null 2>&1
	retun=$?
	if [ $retun -eq 0 ];then
		echo -e "\033[32m NetworkManager Service Running..\033[0m"
	else
		echo -e "\033[31m NetworkManager Service False\033[0m"
		exit 1
	fi
fi
}

# 主体添加team team-slave模块
function add_bond() {
add_slave_network_card=$(nmcli connection add type team-slave con-name ${i} ifname ${i} master ${network_card_name})

nmcli connection add type team con-name ${network_card_name} ifname ${network_card_name} config '{"runner":{"name":'"${network_type}"'}}' >/dev/null 2>&1

retun=$?

if [ $are -eq 0 ];then
    while true;do
	
	read -p "Enter slave network card name[eth0 eth1]: " network_slave_one
        # 判断传入的网卡块数，不能少于2块也不能多余2块。
	# 仅支持俩块网卡进行bond绑定
	length=$(echo ${network_slave_one} |awk '{print $0}' |wc -w)
	if [[ ${length} -lt 2 && ${length} -ne 2 ]];then
		echo -e "\033[31mEnter slave network card length Less 2 error[eth0 eth1]\033[0m"
		continue
	else		
		slave1=$(echo ${network_slave_one} |awk '{print $1}')
		slave2=$(echo ${network_slave_one} |awk '{print $2}')
		for i in $slave1 $slave2;do
		${add_slave_network_card}
		done
		break
	
	fi
    done
fi
	
}

# 主体循环第一步，先检测对应的team是否存在，包括检测传入对应参数是否正确
function check() {

read -p "Enter of team network card name: " network_card_name

if [ -z "$network_card_name" ];then

	echo -e "\033[31m Enter of team network card name error!\033[0m"
	check
else
	netwrok_manager_server 
export are=$(nmcli connection show  |awk '{print $NR}'  |grep -o ${network_card_name} |wc -l)
	if [ ${are} -eq 1 ];then
		echo -e "\033[31m Enter Netwrok Card ${network_card_name} are!\033[0m"
		check
	else
		read -p "Enter Team Type[activebackup|loadbalence|roundrobin]" network_type
		case $network_type in
			
			activebackup)
			active_backup
			;;
			loadbalence)
			active_backup
			;;
			roundrobin)
			active_backup
			;;
			*)
			echo -e "\033[31mERROR:Enter Team ${network_type} Type The unknown\033[0m"
			check			
		esac
	fi	
fi
}
check
