#!/bin/bash

CIUSER=ubuntu
CIPASS=1q2w3e4r
SSHKEY=~/.ssh/tpetkovski_rsa.pub
MEMORY=4096

qm_list_delay=1
qm_start_delay=5

scriptname=$(basename $0)
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

echo -e "Building creation queue.\nThe VMs will be created with the following parameters:\n"
for key in "${!VMS[@]}"; do
	echo "VM: $key => ${VMS[$key]}"
	
	vmdata=${VMS[$key]}
	IFS=',' read -r -a fields <<< "$vmdata"
	VMNAME=${fields[1]}

	qm list | grep --quiet --silent -w $key
	lastcall=$?

	if [[ $lastcall -eq 0 ]]; then
		echo -e "!!! WARNING !!! VM $key ($VMNAME) already exists and will be removed from the creation queue!\n"
		unset VMS[$key]
		lastcall_executed=1
	fi
	sleep $qm_list_delay
done

if [[ $lastcall_executed ]]; then echo -e "\nSome VMs were removed from the initial queue.\nVMs queued to be created: ${!VMS[@]}"; fi
read -e -p "Proceed to create? Y/y[N]" choice

if [[ "$choice" == [Yy]* ]]; then
	for key in "${!VMS[@]}"; do
		vmdata=${VMS[$key]}
		
		IFS=',' read -r -a vmfields <<< "$vmdata"
		NEWGUESTID=$key
		TEMPLATE_GUESTID=${vmfields[0]}
		NEWGUESTNAME=${vmfields[1]}
		TARGET_STORAGE=${vmfields[2]}

		NETPARAMS="--net0 virtio,bridge=vmbr0,firewall=1"
		if [[ ${vmfields[3]} ]]; then
			MACADDR=${vmfields[3]}
			NETPARAMS="--net0 virtio=$MACADDR,bridge=vmbr0,firewall=1"
		fi

		qm clone $TEMPLATE_GUESTID $NEWGUESTID --name $NEWGUESTNAME --full --storage $TARGET_STORAGE
		qm set $NEWGUESTID --ciuser $CIUSER --cipassword=$CIPASS --sshkey $SSHKEY --memory $MEMORY --ipconfig0 ip=dhcp $NETPARAMS
		echo
	done
else
	echo -e "Aborted...\n"
	exit 0
fi

echo -e "VMs created.\n"
for key in "${!VMS[@]}"; do
	qm list | grep -w "$key"; sleep $qm_list_delay
done

echo
read -e -p "Do you want t power on the new VMs? Y/y[N]" choice
if [[ "$choice" == [Yy]* ]]; then
	for key in "${!VMS[@]}"; do
		vmdata=${VMS[$key]}
		IFS=',' read -r -a vmfields <<< "$vmdata"
		VMNAME=${vmfields[1]}
		echo "Power on $key ($VMNAME)"
		qm start $key; sleep $qm_start_delay
	done
else
	exit 0
fi	

