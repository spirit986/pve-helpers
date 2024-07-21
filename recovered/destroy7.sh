#!/bin/bash

qm_destroy_delay=1
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

echo "VMs: ${!VMS[@]}"
read -e -p "Destroy VMs? Y/y[N]" choice

if [[ "$choice" == [Yy]* ]]; then
	read -e -p "Type exactly 'DESTROY' (all caps) to confirm!!! " confirm
	if [[ "$confirm" == "DESTROY" ]]; then
		echo "The VMs will be destroyed in $destroy_initial_delay secs:"
		sleep $destroy_initial_delay

		for id in "${!VMS[@]}"
		do
			echo
			echo "Deleting VM: $id"
			#qm destroy $id
			sleep $qm_destroy_delay
		done
	fi
else
	echo -e "Aborted...\n"
	exit 0
fi
