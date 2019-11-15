#!/bin/bash
# This the cobbler install script
# 2019-08-19
# Yin 17600169910


Work_Dir=$(cd $(dirname $0) && pwd)

Source="${Work_Dir}/function.sh"
[ -f $Source ] && source $Source
Evn="${Work_Dir}/evnfile"

[ -f $Evn ] && source $Evn

export TOP_PID=$$


function Cobbler_Check() {

if [ -z $PACKER ];then
	echo_red "$PACKER Could Not Find"
	exit 10
	kill -9 ${TOP_PID}
fi
if [ -z $Cobbler_Host ];then
	echo_red "$Cobbler_Host Can't be empty"
	exit 11
	kill -9 ${TOP_PID}
fi

if [ -z "$Server_Starting" ];then
	echo_red "$Server_Starting Can't be empty"
	exit 11
	kill -9 ${TOP_PID}
fi

if [ -z "$Cobbler_album" ];then
	echo_red "$Cobbler_album Can't be empty"
	exit 13
	kill -9 ${TOP_PID}
fi

}

function Cobbler_Install() {

Cobarray=$(ls ${PACKER}|awk '{print $0}')

if [ -z "$Cobarray" ];then

	echo_red "$PACKER No software package"
	exit 12
	kill -9 ${TOP_PID}
else
	DHCP=(dhcp dhcp-common dhcp-libs)
        for l in ${DHCP[@]};do
                yum -y remove $l
                sleep 5
        done
	cd $PACKER && yum -y install *.rpm 

fi
	for i in ${Server_Starting[@]};do
		if [ "${Server_Starting[@]:0:1}" == "#" ];then
			continue
		else
			/usr/bin/systemctl restart ${i:2} >/dev/null 2>&1 && Return=$? && [ $Return -eq 0 ] && echo_green "Successful Starting ${i:2}" || echo_red "${i:2} Starting False!"
			$(systemctl is-enabled ${i:2} | grep -qw "disabled")  && /usr/bin/systemctl enable ${i:2} >/dev/null 2>&1 && Return=$? && [ $Return -eq 0 ] && echo_green "Successful Enable ${i:2}" || echo_red "${i:2} already enable!"
		fi
	done


}

function Set_Cobbler_Config() {

if [ ! -f $Cobbler_Config ];then
	
	echo_red "$Conbbler_Config Not Find!"
	exit 12
	kill -9 ${TOP_PID}
else
	echo_green "Motify Sed server: $Cobbler_Host "
	sed -i "s#^server: 127.0.0.1#server: ${Cobbler_Host}#" ${Cobbler_Config}
	sleep 10
	echo_green "Motify Sed next_server: $Cobbler_Host"
	sed -i "s#^next_server: 127.0.0.1#next_server: ${Cobbler_Host}#" ${Cobbler_Config}
	sleep 10
	echo_green "Motify Sed Tftpd disable: no"
	Get_Value=$(awk -F= '/[[:space:]]disable[[:space:]]/{print $2 }' $Cobbler_Config_Tftp)
	[[ "$Get_Value" == "yes" ]] && sed  -i '/[[:space:]]disable/ s/yes/no/' $Cobbler_Config_Tftp
	sleep 10
 	echo_green "Add Cobbler Loaders File: $Get_Loaders_File_Dir"	
	loaders=$(ls $Get_Loaders_File |awk '{print $0}')
	cd $Get_Loaders_File
	for n in ${loaders[@]};do
		\cp -rf $n $Get_Loaders_File_Dir
	done 	
	sleep 10
	MD5=$(openssl passwd -1 -salt "${Cobbler_Pass}" "${Cobbler_Pass}")
	echo_green "Sed default_password_crypted: $MD5"
	sed -i '100d' ${Cobbler_Config}
	sed -i "100a default_password_crypted: \"$MD5\"" ${Cobbler_Config}
	echo_green "Run cobbler sync "
	sleep 10
	echo_green "Sed Run Cobberl DHCP "
	sed -i '21,25d' ${Cobbler_DHCP_Config} 
	sed -i "s#^manage_dhcp: 0#manage_dhcp: 1#" ${Cobbler_Config}
	sed -i "20a subnet $Cobbler_DHCP_Subnet netmask $Cobbler_DHCP_Netmask { \n option routers $Cobbler_DHCP_Routers; \n option domain-name-servers $Cobbler_DHCP_Nameserver; \n option subnet-mask $Cobbler_DHCP_Netmask; \n range dynamic-bootp $Cobbler_DHCP_Range;" ${Cobbler_DHCP_Config}
	/usr/bin/cobbler sync && /usr/bin/systemctl restart cobblerd
	sleep 20

fi
}

function Cobber_Input_Mirrors() {
	
if [ ! -d $MIRRORS ];then
	echo_red "$MIRRORS Not Find"
	exit 15
	kill -9 ${TOP_PID}
else
	cd $MIRRORS
	for o in ${Cobbler_album[@]};do
		[ ! -d ${MIRRORS}/${o%%_*} ] && mkdir -p ${MIRRORS}/${o%%_*} ; umount ${MIRRORS}/${o%%_*} >/dev/null 2>&1 ; mount -t auto -o loop ${o} ${MIRRORS}/${o%%_*}
		Retun1="/var/www/cobbler/ks_mirror/${o}-x86_64"
		if [ ! -d "$Retun1" ];then
		cobbler import --path=${MIRRORS}/${o%%_*} --name=${o} --arch=x86_64 && echo_green "$o Input Ok" 
		cd $KistartDir && cp ./* /var/lib/cobbler/kickstarts/
		for p in $(cobbler profile list);do
			for m in $(ls ./);do
			if [[ $p = $m ]];then
				cobbler profile edit --name $p --kickstart=/var/lib/cobbler/kickstarts/$m
				sleep 10
				cobbler sync >/dev/null 2>&1
				echo_green "Cobbler Server Successful installation."
			fi
			done
		done
		else
		continue
		fi
	     	
	done
fi


}
	
function main() {

Cobbler_Check && Cobbler_Install && Set_Cobbler_Config && Cobber_Input_Mirrors

}

main
