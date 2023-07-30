
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

systemctl enable health-check.timer


pacman -S sudo
vim /etc/sudoers # Allow wheel w/o pw



```
