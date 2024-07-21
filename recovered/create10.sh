#!/bin/bash

scriptname=$(basename $0)
CIUSER=ubuntu
CIPASS=1q2w3e4r
SSHKEY=~/.ssh/tpetkovski_rsa.pub
MASTER_MEMORY=4096
GUEST_MEMORY=4096

qm_list_delay=1
qm_start_delay=5

configfile=$1
if [[ -z $configfile ]]; then
        echo -e "Usage:\n  ./$scriptname <config_file>\n"
        exit 1
fi

# TARGET_STORAGE has three choices
# "local-lvm"
# "mknssd-nvme-thin"
# "kingston-thin-00"

declare -A VMS
#Update the file vms.conf in the following way:
#ID,TEMPLATE_ID,VM_NAME,TARGET_STORAGE,MAC_ADDR
#
# If you fail to provide a unique ID the script will
#   try to remove it from the array
# You still need to make sure that a valid unique MAC address is provided. 
# It is reccomended that you assign the MAC in your DHCP allocation
#   before updating the VM details in the file.  
while IFS=',' read -r item value; do
	VMS["$item"]="$value"
done < $configfile

echo -e "The VMs will be created with the following parameters:\n"
for key in "${!VMS[@]}"; do
	echo "VM: $key => ${VMS[$key]}"

	qm list | grep --quiet --silent -w $key
	lastcall=$?

	if [[ $lastcall -eq 0 ]]; then
		echo -e "!!! WARNING !!! VM $key EXISTS AND WILL BE REMOVED !!!\n"
		unset VMS[$key]
		lastcall_executed=1
	fi
	sleep $qm_list_delay
done

if [[ $lastcall_executed ]]; then echo -e "\nVMs that will be created: ${!VMS[@]}"; fi
read -e -p "Proceed to create? Y/y[N]" choice

if [[ "$choice" == [Yy]* ]]; then
	for key in "${!VMS[@]}"; do
		vmdata=${VMS[$key]}
		
		IFS=',' read -r -a vmfields <<< "$vmdata"
		NEWGUESTID=$key
		TEMPLATE_GUESTID=${vmfields[0]}
		NEWGUESTNAME=${vmfields[1]}
		TARGET_STORAGE=${vmfields[2]}
		MACADDR=${vmfields[3]}

		echo "qm clone $TEMPLATE_GUESTID $NEWGUESTID --name $NEWGUESTNAME --full --storage $TARGET_STORAGE"
		echo "qm set $NEWGUESTID --ciuser $CIUSER --cipassword=$CIPASS --sshkey $SSHKEY --memory $MASTER_MEMORY --ipconfig0 ip=dhcp --net0 virtio=$MACADDR,bridge=vmbr0,firewall=1"
	done
else
	echo -e "Aborted...\n"
	exit 0
fi

echo -e "VMs created.\n"
for key in "${!VMS[@]}"; do
	qm list | grep -w "$key"
	sleep $qm_list_delay
done

read -e -p "Do you want t power on the new VMs? Y/y[N]" choice
if [[ "$choice" == [Yy]* ]]; then
	for key in "${!VMS[@]}"; do
		echo "qm start $key"
		sleep $qm_start_delay
	done
else
	exit 0
fi	

