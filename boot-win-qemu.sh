#!/bin/bash

set -e

mkdir -p build

win_xp_qcow2='build/Windows-XP.qcow2'
win_xp_c_root='build/win_xp_c_root'

if ! [[ -e  "$win_xp_qcow2" ]] ; then
  if [[ -e '/mnt/scratch/torrents/windows-xp-sp3-qcow2/Windows XP.qcow2' ]] ; then
    cp '/mnt/scratch/torrents/windows-xp-sp3-qcow2/Windows XP.qcow2' "$win_xp_qcow2"
  else
    wget -O "$win_xp_qcow2" 'https://ia801409.us.archive.org/34/items/windows-xp-sp3-qcow2/Windows%20XP.qcow2'
  fi
fi

echo "win_xp_qcow2 = $win_xp_qcow2"

# Find the RobotAndRobot.com USB device bus and port; currently no USB chains supported!
lsusb_line=$(lsusb | grep -i 'RobotAndRobot.com')
if [[ -z "$lsusb_line" ]] ; then
  echo "Cannot find a RobotAndRobot.com USB control board, exiting!"
  exit 1
fi
bus_num=$(cut -d' ' -f 2 <<<"$lsusb_line" | sed 's/^0*//')
device_num=$(cut -d' ' -f 4 <<<"$lsusb_line" | sed 's/^0*//' | sed 's/[^0-9]//g')

echo "Forwarding bus $bus_num device $device_num (parsed from $lsusb_line)"

if mount | grep -qi "$win_xp_c_root" ; then
  sudo umount "$win_xp_c_root" || true
  sudo qemu-nbd -d /dev/nbd0 || true
fi

xhost + local: || true

sudo qemu-system-i386 \
  -enable-kvm -cpu host -m 712M \
  -vga std -net nic,model=rtl8139 -net user \
  -drive file="$win_xp_qcow2" \
  -usb -device usb-host,hostbus=$bus_num,hostport=$device_num










