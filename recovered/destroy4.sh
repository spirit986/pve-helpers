#!/bin/bash

qm_destroy_delay=5
destroy_initial_delay=15

scriptname=$(basename $0)
configfile=$1
if [[ -z $configfile ]]; then
        echo -e "Usage:\n  ./$scriptname <config_file>\n"
        exit 1
fi

declare -A VMS
while IFS=',' read -r item value; do
	VMS["$item"]="$value"
done < $configfile

echo -e "\nVMs to be destroyed\n${!VMS[@]} \n"
read -e -p "Destroy VMs? Y/y[N]" choice

if [[ "$choice" == [Yy]* ]]; then
	read -e -p "Type exactly 'DESTORY' (all caps) to confirm!!! " confirm
	if [[ "$confirm" == "DESTORY" ]]; then
		echo "The VMs will be destroyed in $destroy_initial_delay secs. Type CTRL-C at any time to abort."
		sleep $destroy_initial_delay

		for id in "${!VMS[@]}"; do
			vmdata=${VMS[$id]}
			IFS=',' read -r -a fields <<< "$vmdata"
			VMNAME=${fields[1]}

			echo
			echo "Deleting VM: $id ($VMNAME) in $qm_destroy_delay seconds"; sleep $qm_destroy_delay
			echo "qm destroy $id"
		done
	else
		echo -e "You need to type DESTORY to confrim, not DESTROY...\n"
		exit 2
	fi
else
	echo -e "Aborted...\n"
	exit 0
fi
