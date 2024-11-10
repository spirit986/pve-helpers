# pve-helpers
A collection of VM management scripts for a Proxmox PVE server

- `create_pve_vms.sh` - Create VMs from a config file
- `destroy_pve_vms.sh` - Destroy VMs from a config file
- `rollback_pve_vms.sh` - Rollback VMs to a predefined snapshot
- `start_pve_vms.sh`/`stop_pve_vms.sh` - Start/stop VMs

## Prerequisites
### 1. `cloud-init` prepared VM template
A cloud-init ready VM template, that will be used to create other VMs. Usefull guides of how to make one can be found from [Techno Tim](https://technotim.live/posts/cloud-init-cloud-image/) or from the official [Proxmox Documentation](https://pve.proxmox.com/wiki/Cloud-Init_Support).

### 2. [Optional] Static IP address DHCP reservations 
If you wish your VMs to have persistent IP addresses you need to reserve their MAC addresses in your DHCP server with the appropriate IP Address.

## Quick Start
### Define your `vms.conf` file
Create a `vms.conf` file based on the `vms-example.conf`.
The structure is as follows:
```
VM_ID,TEMPLATE_ID,VM_NAME,DATASTORE,VM_MAC_ADDR
```
Remember: **No spaces, no empty lines!**

##### Explanation:
- `VM_ID` - (UNIQUE)The new ID of the VM that is about to be create
- `TEMPLATE_ID` - Cloud-init ready VM template
- `VM_NAME` - The name/alias of the new VM
- `DATASTORE` - Proxmox datastore where the VM main disk will be created
- `VM_MAC_ADDR` - The only optional parameter. If you omit the MAC address field the VM will be assigned a MAC automatically.

**Example:**
```
5000,50000,k3sm01,mknssd-nvme-thin,BC:24:11:7E:15:41
5001,50000,k3sm02,kingston-thin-00,BC:24:11:10:EA:62
5002,50000,k3sm03,local-lvm
5010,50000,k3sw01,mknssd-nvme-thin
```

---
#### Reccomendation
To avoid loosing track of your managed VMs, it is reccomended that you have one `vms.conf` file for all of your VMs, and another `vms_current.conf` file for just the VMs you are working on currently.

---

### Create the VMs
Simply execute the `create_pve_vms.sh `script against your config file:
```
./create_pve_vms.sh vms.conf
```

Once your VMs are powered on and ready it is reccomended that you install some apps and tools without too much configuration. 
For example I like to update the VMs, and install prerequisite software for installation of a kubernetes cluster, but not the kuberenetes cluster.

Then create snapshots called `FRESH` for all of them.

### Rollback VMs to a starting snapshot
The script `rollback_pve_vms.sh` can rollback the VMs to a snapshot of your choice (FRESH by default)
```
./rollback_pve_vms vms_current.conf start
```
This will power-off the vms, rollback to FRESH and then start them at the end.


# TO-DO

##### 2023-11-10 - Automate template creation from cloud image

Rough commands to be made into a script:
```bash
cd /var/lib/vz-image/template/iso/
export IMGNAME="debian-12-generic-amd64-20241004-1890.raw"
export IMGURL="https://cdimage.debian.org/images/cloud/bookworm/20241004-1890/$IMGNAME"
export IMG512SUM="a22fa2194d8b6ff95a39959cc088f2de28aa1dbe5c61509f41d6ad080e1872ec6d70f1d65da76e3e1691a74a9a55cb36718549b0be8677dfd89189ff457db901"

wget $IMGURL
sha512sum $IMGNAME
echo $IMG512SUM

cp $IMGNAME $IMGNAME.original
virt-customize -a $IMGNAME --install qemu-guest-agent,ncat,net-tools,bash-completion
virt-customize -a $IMGNAME --delete /etc/machine-id --delete /var/lib/machine-id
virt-customize -a $IMGNAME --run-command systemd-machine-id-setup

export VMID=50200 
export VMNAME='debian12-cloud'
export DATASTORE='datastore_name'

qm create     $VMID --memory 2048 --core 1 --name $VMNAME --net0 virtio,bridge=vmbr0,firewall=1
qm importdisk $VMID $IMGNAME $DATASTORE
qm set        $VMID --scsihw virtio-scsi-single --scsi0 "$DATASTORE":"vm-$VMID-disk-0"
qm resize     $VMID scsi0 +18G
qm set        $VMID --ide2 "$DATASTORE":cloudinit
qm set        $VMID --boot c --bootdisk scsi0
qm set        $VMID --serial0 socket --vga serial0
qm set        $VMID --agent enabled=1,fstrim_cloned_disks=1

qm template $VMID
```

