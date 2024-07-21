#!/bin/bash

SNAPNAME=FRESH
qm_stop_delay=1
qm_rollback_delay=10

scriptname=$(basename $0)
configfile=$1
if [[ -z $configfile ]]; then
	echo -e "Usage:\n  ./$scriptname <config_file>\n"
	exit 1
fi

startvm=$2
if [[ -z $startvm ]] || [[ $startvm != "start" ]]; then startvm="--start 0"; else startvm="--start 1"; fi
if [[ $startvm != "--start 1" ]]; then echo -e "Tip! You can use the \"start\" parameter\n  ./rollback_k3s_vms.sh <config_file> start\nfor the VMs to be automatically started after the rollback.\n"; fi

declare -a VMS
while IFS=',' read -r item value; do
        VMS["$item"]="$value"
done < $configfile

echo "VMs: ${!VMS[@]}"

read -e -p "Revert VMs? Y/y[N]" choice

if [[ "$choice" == [Yy]* ]]; then
	echo -e "Stopping VMs, and revertng to $SNAPNAME"
	for id in "${!VMS[@]}"
	do
		vmdata=${VMS[$id]}
                IFS=',' read -r -a fields <<< "$vmdata"
                VMNAME=${fields[1]}
		echo "Stopping VM $id ($VMNAME)"; sleep $qm_stop_delay
		echo "qm stop $id" 
	done

	echo "Rolling back VMs to $SNAPNAME"
	for id in "${!VMS[@]}"
	do
		vmdata=${VMS[$id]}
                IFS=',' read -r -a fields <<< "$vmdata"
                VMNAME=${fields[1]}
		echo "Rollback VM $id ($VMNAME)"; sleep $qm_rollback_delay
		echo "qm rollback $id $SNAPNAME $startvm"
	done
else
	echo "Aborted..."
	exit 0
fi

