#!/bin/bash

# This script is used for step 1 of deployment - grab any .iso image,
# boot into it, perform the install on a local SD card,
# when done put the SD card into the pi.
# We assume SSH and network access is configured here.

set -e # exit immediately on any errors in script

source config-vars.sh

DISK_TO_INSTALL_TO="$1"
if [ -z "$DISK_TO_INSTALL_TO" ] ; then
    echo "Please select an un-mounted disk to install to."
    echo "If you do not see your disk below please un-mount it first."
    if which lshw >/dev/null 2>&1 ; then
        echo ""
        MOUNTED_DISK_DEVICES=$(mount | grep '/dev/.*on /' | sed 's/ .*//g' | tr '\n' '|')
        MOUNTED_DISK_DEVICES=${MOUNTED_DISK_DEVICES::-1} # trim last | so we don't match .* in grep
        MOUNTED_DISK_DEVICES=$(sed 's/p1|/|/g' <<< "$MOUNTED_DISK_DEVICES")
        MOUNTED_DISK_DEVICES=$(sed 's/1|/|/g' <<< "$MOUNTED_DISK_DEVICES")
        
        lshw -class disk -json 2>/dev/null |\
            jq -r '.[] | select( .logicalname | contains("/dev/") ) | select( has("size") == true ) | "\(.logicalname) \(.product) built by \(.vendor), \(.size/1000000000 | floor) gigabytes"' |\
            grep -v -E "$MOUNTED_DISK_DEVICES" |\
            awk '{ print; print ""; }'
    else
        echo ""
        echo "<Please install 'lshw' for a list of disks, vendors, and sizes>"
        echo ""
    fi
    read -p "Which disk (under /dev/) should be installed to? " DISK_TO_INSTALL_TO
fi

echo "Using disk $DISK_TO_INSTALL_TO"

mkdir -p vm-files

if ! [ -e "vm-files/bcm2710-rpi-3-b-plus.dtb" ] ; then
    wget -O "vm-files/bcm2710-rpi-3-b-plus.dtb" "https://farabimahmud.github.io/emulate-raspberry-pi3-in-qemu/bcm2710-rpi-3-b-plus.dtb"
fi

if ! [ -e "vm-files/ArchLinuxARM-rpi-aarch64-latest.tar.gz" ] ; then
    wget -O "vm-files/ArchLinuxARM-rpi-aarch64-latest.tar.gz" "http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-aarch64-latest.tar.gz"
fi

# Partition $DISK_TO_INSTALL_TO IF not already partitioned!
echo ""
touch "vm-files/partitioned-disk-name.txt"
fdisk -l "$DISK_TO_INSTALL_TO"
if ! grep -q "$DISK_TO_INSTALL_TO" "vm-files/partitioned-disk-name.txt" ; then
    read -p "About to partition $DISK_TO_INSTALL_TO, continue? (y/n) " YN
    if ! grep -q "y" <<< "$YN" ; then
        echo "Exiting..."
        exit 1
    fi
    sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | sudo fdisk "$DISK_TO_INSTALL_TO"
  o # clear the in memory partition table
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk 
  +250M # 250 MB boot parttion
  t # change type
  c # set the first partition to type W95 FAT32 (LBA)
  n # new partition
  p # primary partition
  2 # partion number 2
    # default, start immediately after preceding partition
    # default, extend partition to end of disk
  w # write the partition table
  q # and we're done
EOF
    echo "$DISK_TO_INSTALL_TO" > "vm-files/partitioned-disk-name.txt" 
fi
echo "Partitioning complete"


echo ""


echo qemu-system-aarch64 \
    -M raspi3b \
    -cpu cortex-a72 \
    -append "rw earlyprintk loglevel=8 console=ttyAMA0,115200 dwc_otg.lpm_enable=0 root=/dev/mmcblk0p2 rootdelay=1" \
    -dtb "vm-files/bcm2710-rpi-3-b-plus.dtb" \
    -sd $DISK_TO_INSTALL_TO \
    -kernel kernel8.img \
    -m 1G -smp 4 \
    -serial stdio \
    -usb -device usb-mouse -device usb-kbd \
  -device usb-net,netdev=net0 \
  -netdev user,id=net0,hostfwd=tcp::5555-:22 \


