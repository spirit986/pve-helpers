#!/bin/bash

SNAPNAME=FRESH
qm_stop_delay=1
qm_rollback_delay=10

configfile=$1
if [[ -z $configfile ]]; then
	echo -e "Usage:\n  ./rollback_k3s_vms.sh <config_file>\n"
	exit 1
fi

startvm=$2
if [[ -z $startvm ]] || [[ $startvm != "start" ]]; then startvm="--start 0"; else startvm="--start 1"; fi
if [[ $startvm != "--start 1" ]]; then echo -e "Tip! You can use the \"start\" parameter\n  ./rollback_k3s_vms.sh <config_file> start\nfor the VMs to be automatically started after the rollback.\n"; fi
echo $startvm

declare -a VMS
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

echo "VMs: ${!VMS[@]}"

read -e -p "Revert VMs? Y/y[N]" choice

if [[ "$choice" == [Yy]* ]]; then
	echo -e "Stopping VMs, and revertng to $SNAPNAME"
	for id in "${!VMS[@]}"
	do
		echo "Stopping VM $id"
		echo "qm stop $id"
		sleep $qm_stop_delay
	done

	echo "Rolling back VMs to $SNAPNAME"
	for id in "${!VMS[@]}"
	do
		echo
		echo "Rollback VM $id"
		echo "qm rollback $id $SNAPNAME $startvm"
		sleep $qm_rollback_delay
	done
else
	echo "Aborted..."
	exit 0
fi

