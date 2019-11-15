#!/bin/bash
# BML 2.8 一键集群清理脚本
# 2019-09-27

work_dir=$(pwd)
config_file=${work_dir}/config
shell_file=${work_dir}/shell
Tar_Dir="${shell_file}/remove.tar"

[ -f $config_file ] && source ${config_file}

source $work_dir/function.sh


function scp_slave() {

echo "${SLAVE_LIST}" | awk '{if(NF>0)print $0}' |sort |uniq |while read slave
do
	slave_ip=$(echo $slave|awk '{print $2}')
	slave_host=$(echo $slave|awk '{print $1}')
	green_echo "-------------------------------"
	green_echo "|   transfer    list          |"
	green_echo "|-----------------------------|"
	green_echo "| ip: $slave_ip            |"
	green_echo "-------------------------------"
	green_echo "Begin scp to host $slave_ip"
	sleep 3
	ssh -n -p ${SLAVE_SSH_PORT} root@${slave_ip} "mkdir -p ${SLAVE_PACKAGES_PATH}/clean_bml_2.8"
	scp $Tar_Dir root@${slave_ip}:${SLAVE_PACKAGES_PATH}/ >/dev/null 2>&1
	ssh -n -p "${SLAVE_SSH_PORT}" root@"${slave_ip}" "cd ${SLAVE_PACKAGES_PATH} && tar -xf remove.tar -C ./clean_bml_2.8"
	return=$?
	if [ $return -eq 0 ];then
		green_echo "${slave_ip} scp successful~"
	fi
done

}


# 进入slave主机执行脚本文件
function ssh_slave() {
echo "${SLAVE_LIST}" | awk '{if(NF>0)print $0}' |sort |uniq |while read slave
do
  	if [ "${slave:0:1}" == "#" ];then
                continue
	fi
	action_slave_name=$(echo $slave |awk '{print $1}')
	action_slave_ip=$(echo $slave |awk '{print $2}')

                for i in $(echo $SLAVE_INSTALL_CONPONENT_LIST);do
                name=${i##*.}
		ssh -n -p $SLAVE_SSH_PORT root@$action_slave_ip "cd $SLAVE_PACKAGES_PATH/clean_bml_2.8 && sh $name $*" >/dev/null 2>&1

		green_echo "------------------------------------------------"
		green_echo "|    action               list                 |"
		green_echo "|----------------------------------------------|"
		green_echo "|   host: $action_slave_ip                       | "
		green_echo "|   action: remove $name                              "
		green_echo "|----------------------------------------------|"
		sleep 3

                done
               
done

}

# 打包slave清除脚本文件
function buid_file() {
red_echo "action buit_file......"
sleep 5
tar -rvf $Tar_Dir function.sh
for i in $(echo ${SLAVE_INSTALL_CONPONENT_LIST});do
                if [ "${i:0:1}" == "#" ];then
                        continue
                elif [[ "${i:0:1}" =~ ^[0-9] ]];then
                       	file_name=${i##*.}
                if [ -f "${shell_file}/${file_name}" ];then
                green_echo "load $file_name to remove_slave.tar"
                sleep 2
                cd $shell_file
                tar -rvf $Tar_Dir $file_name >/dev/null 2>&1
                else
                red_echo "$file_name skip...."
                continue
                fi
        fi
done
red_echo "action scp slave file ....."
sleep 5
scp_slave $*
red_echo "action ssh slave remove cluster ....."
ssh_slave $*
}


# 当slave节点不是远程集群执行时，单机清除动作
function local_slave() {

cd ${work_dir}/remove_shell
for l in $(echo $SLAVE_INSTALL_CONPONENT_LIST);do
                name=${l##*.}
      if [ -f "$remove_dir/$name" ];then
          sh $name $1
       else
          red_echo "$name remove skip ..."
      fi
done

}

# 清除master主机环境执行动作
function master() {

for i in $(echo ${MASTER_INSTALL_CONPONENT_LIST});do
	if [ ${i:0:1} == "#" ];then
		continue
	else
		O=${i##*.}
	cd $shell_file
	if [ -f "${shell_file}/${O}" ];then
		sh $O $1
		sleep 5	
	else
		red_echo "skip $O...."
		sleep 3
		continue
	fi
	fi
done

}

function run() {

if [ "$1" == "cluster_slave" ];then
	buid_file $*	
elif [ "$1" == "local_slave" ];then
	local_slave $*		
elif [ "$1" == "master" ];then
	master $*
else
	if [ $# -eq 0 ] || [ "$1" != "cluster_slave|local_slave|master" ];then
		red_echo "Please enter the:cluster_slave|local_slave|master"
		exit
	fi
fi
	
}
run  $*

