#!/bin/bash

set -e

win_xp_qcow2='build/Windows-XP.qcow2'
win_xp_c_root='build/win_xp_c_root'

sudo modprobe nbd max_part=16

if mount | grep -qi "$win_xp_c_root" ; then
  sudo umount "$win_xp_c_root" || true
  sudo qemu-nbd -d /dev/nbd0 || true
fi

sudo qemu-nbd -c /dev/nbd0 "$win_xp_qcow2"
mkdir -p "$win_xp_c_root"

sudo fdisk -l /dev/nbd0

sudo mount /dev/nbd0p1 "$win_xp_c_root"

echo ''
echo "Windows XP C: drive mounted at $win_xp_c_root"
echo ''
ls -alh "$win_xp_c_root"
echo ''



