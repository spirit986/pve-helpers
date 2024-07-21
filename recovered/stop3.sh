#!/bin/bash

qm_stop_delay=3
configfile=$1
if [[ -z $configfile ]]; then
        echo -e "Usage:\n  ./$scriptname <config_file>\n"
        exit 1
fi

declare -a VMS
while IFS=',' read -r item value; do
        VMS["$item"]="$value"
done < $configfile

echo "VMs: ${!VMS[@]}"
read -e -p "Stop VMs? Y/y[N]" choice
if [[ "$choice" == [Yy]* ]]; then
	for id in "${!VMS[@]}"
	do
		vmdata=${VMS[$id]}
		IFS=',' read -r -a fields <<< "$vmdata"
		VMNAME=${fields[1]}
		echo -e "\nPower off VM $id ($VMNAME)"; sleep $qm_stop_delay
		echo "qm stop $id"
	done
else
	echo "Aborted..."
	exit 0
fi

