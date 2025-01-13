# Quick and dirty proxmox notes scratchpad

### Shows the phisical volumes associated with the volume group
`vgdisplay vg-mknssd -v`

### Also show the metadata size
######  Important if you utilize a thinpool
`lvs -a`

### Create a thin-pool for VMs usage
###### Make sure the chunksize is 256K | https://forum.proxmox.com/threads/thin-lvm-and-zeroing-chunk-size.56262/
`lvcreate --type thin-pool -n lv-mknssd-nve-storage --chunksize 256K --size 780G vg-mknssd-nve`


### Extend the default metadata size after thin-pool creation
lvextend --poolmetadatasize +10G /dev/vg-mknssd-nve/lv-mknssd-nve-storage

## Increase VM LVM partition size on the fly

0. Check the PV inside the VM (/dev/sdb in this case)
The command bellow shows 0 PE (Phisical Extents) meaning that all sectors of the disc are allocated.
```bash
$ pvdisplay /dev/sdb
  --- Physical volume ---
  PV Name               /dev/sdb
  VG Name               vg-storage
  PV Size               300.00 GiB / not usable 4.00 MiB
  Allocatable           yes (but full)
  PE Size               4.00 MiB
  Total PE              76799
  Free PE               0
  Allocated PE          76799
  PV UUID               EdBXQQ-7NDs-ZhQa-tgJO-2jML-Jgt0-POQbhv
```


1. Increase the virtual disk size from the hypervisor, example plus 100GB, from 300 to 400GB
2. Login inside the VM

3. Check if the kernel detected the hardware change:
```bash
$ dmesg | grep sdb # assuming the disk position is in /dev/sdb
[    1.155321] sd 3:0:0:1: [sdb] 629145600 512-byte logical blocks: (322 GB/300 GiB)
[    1.155773] sd 3:0:0:1: [sdb] Write Protect is off
[    1.156211] sd 3:0:0:1: [sdb] Mode Sense: 63 00 00 08
[    1.156302] sd 3:0:0:1: [sdb] Write cache: enabled, read cache: enabled, doesn't support DPO or FUA
[    1.162327] sd 3:0:0:1: [sdb] Attached SCSI disk
[ 3477.899985] sd 3:0:0:1: [sdb] 838860800 512-byte logical blocks: (429 GB/400 GiB)
[ 3477.900054] sdb: detected capacity change from 629145600 to 838860800
root@samba:~#
```

4. Increase the PV. This will detect the new PV size.
```bash
$ pvresize /dev/sdb
  Physical volume "/dev/sdb" changed
  1 physical volume(s) resized or updated / 0 physical volume(s) not resized
```

6. Verify
The command bellow FREE PE (Free Phisical Extents) shows  that now there are PEs available to allocation to Logical volumes
```bash
$ pvdisplay /dev/sdb
  --- Physical volume ---
  PV Name               /dev/sdb
  VG Name               vg-storage
  PV Size               <400.00 GiB / not usable 3.00 MiB
  Allocatable           yes
  PE Size               4.00 MiB
  Total PE              102399
  Free PE               25600
  Allocated PE          76799
  PV UUID               EdBXQQ-7NDs-ZhQa-tgJO-2jML-Jgt0-POQbhv
```

8. Increase the LV (Not, do not get confused by the VG). The VG already is made up of ONE PV (/dev/sdb)
```bash
$ lvextend /dev/vg-storage/lv-storage --extents +100%FREE
  Size of logical volume vg-storage/lv-storage changed from <300.00 GiB (76799 extents) to <400.00 GiB (102399 extents).
  Logical volume vg-storage/lv-storage successfully resized.
```

10. Verify.
The new LV size as shown. The VG shows 0 Free PE because we have again allocated the available storage to our LV.
```bash
vgdisplay vg-storage --verbose
  --- Volume group ---
  VG Name               vg-storage
  System ID
  Format                lvm2
  Metadata Areas        1
  Metadata Sequence No  4
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                1
  Open LV               1
  Max PV                0
  Cur PV                1
  Act PV                1
  VG Size               <400.00 GiB
  PE Size               4.00 MiB
  Total PE              102399
  Alloc PE / Size       102399 / <400.00 GiB
  Free  PE / Size       0 / 0
  VG UUID               EaXKDF-Z0sL-FnUZ-WxRy-ALac-0NXO-ExKevq

  --- Logical volume ---
  LV Path                /dev/vg-storage/lv-storage
  LV Name                lv-storage
  VG Name                vg-storage
  LV UUID                CoiRfx-Xg71-w5Gz-e4sC-wZ2U-FZpN-HFsBx3
  LV Write Access        read/write
  LV Creation host, time samba.tomspirit.me, 2023-11-19 15:47:49 +0000
  LV Status              available
  # open                 1
  LV Size                <400.00 GiB
  Current LE             102399
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     256
  Block device           253:0

  --- Physical volumes ---
  PV Name               /dev/sdb
  PV UUID               EdBXQQ-7NDs-ZhQa-tgJO-2jML-Jgt0-POQbhv
  PV Status             allocatable
  Total PE / Free PE    102399 / 0
```

8. Finally, increase the partition size inside the LV.
```bash
$ resize2fs /dev/vg-storage/lv-storage
resize2fs 1.46.5 (30-Dec-2021)
Filesystem at /dev/vg-storage/lv-storage is mounted on /storage; on-line resizing required
old_desc_blocks = 38, new_desc_blocks = 50
The filesystem on /dev/vg-storage/lv-storage is now 104856576 (4k) blocks long.
```


#### Error:
`TASK ERROR: activating LV 'vg-mknssd-nve/lv-mknssd-nve-storage' failed:   Activation of logical volume vg-mknssd-nve/lv-mknssd-nve-storage is prohibited while logical volume vg-mknssd-nve/lv-mknssd-nve-storage_tmeta is active.`

###### Solution:
From: [https://forum.proxmox.com/threads/local-lvm-not-available-after-kernel-update-on-pve-7.97406/page-2#post-430860](https://forum.proxmox.com/threads/task-error-activating-lv-pve-data-failed-activation-of-logical-volume-pve-data-is-prohibited-while-logical-volume-pve-data_tdata-is-active.106225/)
```bash
# From the manpages `lvchange`, switches -a means Activate followed by y(yes) or n(no)

lvchange -an vg-mknssd-nve/lv-mknssd-nve-storage_tdata
lvchange -an vg-mknssd-nve/lv-mknssd-nve-storage_tmeta
lvchange -ay vg-mknssd-nve/lv-mknssd-nve-storage
```

Also check: https://forum.proxmox.com/threads/local-lvm-not-available-after-kernel-update-on-pve-7.97406/page-2#post-430860 if the problem persists.
