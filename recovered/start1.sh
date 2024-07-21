#!/bin/bash

qm_start_delay=5

scriptname=$(basename $0)
configfile=$1
if [[ -z $configfile ]]; then
        echo -e "Usage:\n  ./$scriptname <config_file>\n"
        exit 1
fi

declare -a VMS
while IFS=',' read -r item value; do
	VMS["$item"]="$value"
done < $configfile

echo "${!VMS[@]}"
read -e -p "Power on VMs? Y/y[N] " choice
if [[ "$choice" == [Yy]* ]]; then
	for id in "${!VMS[@]}"
	do
		vmdata=${VMS[$id]}
                IFS=',' read -r -a fields <<< "$vmdata"
                VMNAME=${fields[1]}
		echo -e "\nPower on VM $id ($VMNAME)"; sleep $qm_start_delay
		qm start $id 
	done
else
	echo "Aborted..."
	exit 0
fi

