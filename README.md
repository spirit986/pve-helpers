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
