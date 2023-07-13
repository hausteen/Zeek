#!/bin/bash

# Author: Austin Hunt
# Date: 12 July 2023
# Version: 1.0

# Purpose of the script:
# Install Zeek on Debian:
# Install zeek
# Set mirror interface
# Create zeek systemd service
# Create systemd service to set mirror interface in promiscuous mode
# Add the zeek/bin folder to the path
# Set zeek logs to json output format
# Set the zeek port number
# Disable the zeek emails
# Change the zeek log rotation intervals

# Usage:
# Step 1: Make the script executable (chmod +x install_zeek_debian.sh).
# Step 2: Run the script (./install_zeek_debian.sh)

# Make sure that this is run as the root user.
if [[ $(whoami) != "root" ]]; then
    echo "This script needs to be run as \"root\"."
    exit
fi

os_name=$(grep -E "^ID=" /etc/os-release | cut -d "=" -f 2)
os_version=$(grep -E "^VERSION_ID=" /etc/os-release | cut -d "\"" -f 2)

# This script is built for Debian, but the user can still run this if they choose to.
if [[ $os_name != "debian" ]]; then
    echo "This script was meant for Debian only. It may not work on your distro."
    while true; do
        read -r -p "Proceed anyway? [y/n]: " proceed_anyway_answer
        case $proceed_anyway_answer in
            [nN] | [nN][oO])
                exit
                ;;
            [yY] | [yY][eE][sS])
                break
                ;;
        esac
    done
fi

# Ask if we should install Zeek
while true; do
    read -r -p "Install Zeek? [y/n]: " install_zeek_answer
    case $install_zeek_answer in
        [nN] | [nN][oO])
            exit
            ;;
        [yY] | [yY][eE][sS])
            break
            ;;
    esac
done

# Install packages for Zeek
apt install -y ethtool

# Find the mirror interface that Zeek should listen on. We do this by looking for an interface with no IPv4 address.
mirror_interface=$(ip --brief a | grep -v "\." | cut -d " " -f 1)

# Create systemd service to:
# Bring the mirror interface up
# Set the mirror interface in promiscous mode
# Disable hardware offloading, arp, and multicast
echo -e "[Unit]\nDescription=Enable promiscuous mode on the mirror interface\nAfter=network-online.target\n\n[Service]\nType=oneshot\nExecStart=/usr/sbin/ip link set $mirror_interface up\nExecStart=/usr/sbin/ip link set $mirror_interface promisc on\nExecStart=/usr/sbin/ip link set $mirror_interface arp off\nExecStart=/usr/sbin/ip link set $mirror_interface multicast off\nExecStart=/usr/sbin/ethtool -K $mirror_interface tso off\nExecStart=/usr/sbin/ethtool -K $mirror_interface gso off\nExecStart=/usr/sbin/ethtool -K $mirror_interface gro off\nExecStart=/usr/sbin/ethtool -K $mirror_interface lro off\nRemainAfterExit=yes\n\n[Install]\nWantedBy=default.target" >> /etc/systemd/system/promisc.service
chmod 644 /etc/systemd/system/promisc.service
systemctl daemon-reload
systemctl enable promisc.service

# Update sources.list with the Zeek repo and add the gpg key
echo "deb http://download.opensuse.org/repositories/security:/zeek/$(echo ${os_name^})_$os_version/ /" | tee /etc/apt/sources.list.d/security:zeek.list
curl -fsSL https://download.opensuse.org/repositories/security:zeek/$(echo ${os_name^})_$os_version/Release.key | gpg --dearmor | tee /etc/apt/trusted.gpg.d/security_zeek.gpg > /dev/null
apt update
apt install -y zeek-lts

# Find the base zeek folder location
if [[ -d "/opt/zeek/" ]]; then
    zeek_base_folder="/opt/zeek"
elif [[ -d "/usr/local/zeek/" ]]; then
    zeek_base_folder="/usr/local/zeek"
fi

# Add the Zeek bin folder to the path
for i in $(ls /home/); do
    echo "export PATH=$zeek_base_folder/bin:\$PATH" >> /home/$i/.bashrc
done
echo "export PATH=$zeek_base_folder/bin:\$PATH" >> /root/.bashrc

# Zeek ignore checksums
echo -e "\n# Ignore checksums\nredef ignore_checksums = T;" >> $zeek_base_folder/share/zeek/site/local.zeek

# Zeek output json logs instead of tsv
echo -e "\n# Output json logs instead of tsv\n@load policy/tuning/json-logs.zeek" >> $zeek_base_folder/share/zeek/site/local.zeek

# Set the mirror interface in the zeek node config
sed -Ei "s/eth0$/$mirror_interface/" $zeek_base_folder/etc/node.cfg

# Set the zeek port number
echo -e "\n# Set the port number\nZeekPort = 27760" >> $zeek_base_folder/etc/zeekctl.cfg

# Disable the zeek emails
echo -e "\n# Disable Zeek Emails\nSendMail =" >> $zeek_base_folder/etc/zeekctl.cfg

# Disable the zeek port warning
# echo -e "\n# Disable Zeek port warning\nzeek_port_warning.disable = 1" >> $zeek_base_folder/etc/zeekctl.cfg

# Set the zeek log rotation to 1 day
sed -Ei "s/^LogRotationInterval\s=\s3600/LogRotationInterval = 86400/" $zeek_base_folder/etc/zeekctl.cfg

# Set the zeek log deletion to 365 days
sed -Ei "s/^LogExpireInterval\s=\s0/LogExpireInterval = 365day/" $zeek_base_folder/etc/zeekctl.cfg

# Create Zeek systemd service
echo -e "[Unit]\nDescription=Zeek\nAfter=promisc.service\n\n[Service]\nType=forking\nExecStart=$zeek_base_folder/bin/zeekctl deploy\nExecStop=$zeek_base_folder/bin/zeekctl stop\nRemainAfterExit=yes\n\n[Install]\nWantedBy=default.target" >> /etc/systemd/system/zeek.service
chmod 644 /etc/systemd/system/zeek.service
systemctl daemon-reload
systemctl enable zeek.service

# Ask if we can reboot the system since everything finished
while true; do
    read -r -p "Installation finished. A reboot is required. Reboot now? [y/n]: " reboot_required_answer
    case $reboot_required_answer in
        [nN] | [nN][oO])
            exit
            ;;
        [yY] | [yY][eE][sS])
            reboot
            ;;
    esac
done
