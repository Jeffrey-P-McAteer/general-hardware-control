
```bash
# We're real boring, the software is controlled by the user "user"
useradd -m -G wheel user
passwd user # user

# Overwrite DNS settings from host
echo "nameserver 192.168.5.1" > /run/systemd/resolve/resolv.conf

pacman -S vim
vim /etc/pacman.d/mirrorlist

pacman -Syu

pacman -S openssh
systemctl enable sshd

vim /health-check.sh <<EOF
#!/bin/bash

network_to_connect_to='MacHome 2.4ghz'
wlan_devs=(
  wlan0
  wlan1
  wlan2
)
for wlan in "${wlan_devs[@]}" ; do
  iwctl station "$wlan" scan
  sleep 1
  iwctl station "$wlan" connect "$network_to_connect_to"
done

EOF

vim /etc/systemd/system/health-check.service <<EOF
[Unit]
Description=Health Check

[Service]
Type=oneshot
ExecStart=/bin/bash /health-check.sh
EOF
vim /etc/systemd/system/health-check.timer <<EOF
[Unit]
Description=Health Check

[Timer]
OnBootSec=45s
# every 3 minutes after activation
OnUnitActiveSec=3m


[Install]
WantedBy=timers.target
EOF

pacman -S iwd
systemctl enable iwd.service

pacman -S dhcpcd
systemctl enable dhcpcd.service

systemctl enable health-check.timer


pacman -S sudo
vim /etc/sudoers # Allow wheel w/o pw


# 2023-08-07, looking into controlling the board w/o connected motor.
sudo pacman -S usbutils
lsusb # Found "RobotAndRobot.com RNR ECO MOTION 2.0"

sudo pacman -S ntp
sudo systemctl enable --now ntpd.service

sudo pacman -Sy git base-devel wget python python-pip
sudo pacman -Sy xmlto kmod inetutils bc libelf git cpio perl tar xz


# Build a linux realtime kernel via
# https://wiki.archlinux.org/title/Kernel/Traditional_compilation#Preparation

sudo fallocate -l 24G /linux-build-ssd/swapfile
sudo chmod 600 /linux-build-ssd/swapfile
sudo mkswap /linux-build-ssd/swapfile
sudo swapon /linux-build-ssd/swapfile

# See https://wiki.archlinux.org/title/Kernel/Traditional_compilation
cd /linux-build-ssd
wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.4.6.tar.xz
tar -xvf linux-6.4.6.tar.xz

wget https://cdn.kernel.org/pub/linux/kernel/projects/rt/6.4/patch-6.4.6-rt8.patch.xz
mv linux-6.4.6 linux-6.4.6-rt8 # rename to keep self sane

cd linux-6.4.6-rt8
xz -d ../patch-6.4.6-rt8.patch.xz
patch -p1 <../patch-6.4.6-rt8.patch

# Copy Arch ARM config in
zcat /proc/config.gz > .config

# https://jack23247.github.io/blog/linux/building-preempt-rt/
# Select "General Setup -> Preemption Model and select Fully Preemptible Kernel (Real-Time)"
make menuconfig

make -j4
make -j4 modules
make modules_install
make -j4 bzImage
cp -v arch/x86/boot/bzImage /boot/vmlinuz-linux64-rt

# Also note long-running procs can be spawned with eg
# sudo systemd-run --uid=1001 --gid=1001 --working-directory=/linux-build-ssd/linux-6.4.6-rt8 -r -u async-kernel-build make -j4 ; journalctl -f -u async-kernel-build



## Yay
cd /opt/
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si


###
## C Code build below
###

yay -Sy pigpio
# Possibly; sudo systemctl enable --now pigpiod.service

gcc -g -o gpio-motor-control gpio-motor-control.c -lpigpio -lrt -lpthread


```
