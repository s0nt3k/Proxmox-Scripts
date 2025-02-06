#!/bin/bash

# Copyright (c) 2021-2025 s0nt3k
# Author: s0nt3k
# Co-Author:
# License: MIT
# 
# Source:

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root." >&2
    exit 1
fi

# Set Proxmox VE VM parameters
VMID=1020
VMNAME="request-tracker"
CPUS=2
MEMORY=4096
IPADDR="10.0.10.22/24"
GATEWAY="10.0.10.254"
ISO_IMAGE="local:iso/debian-12.iso"

# Create VM
qm create $VMID --name $VMNAME --memory $MEMORY --cores $CPUS --net0 virtio,bridge=vmbr0 --ipconfig0 ip=$IPADDR,gw=$GATEWAY

# Set OS and install Debian 12
qm set $VMID --boot order=scsi0 --scsihw virtio-scsi-pci --ide2 $ISO_IMAGE,media=cdrom
qm start $VMID

# Enable SSH access
apt update && apt install -y openssh-server
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
echo 'VerboseMode yes' >> /etc/ssh/sshd_config
systemctl restart ssh

# Install required dependencies
apt install -y apache2 mariadb-server mariadb-client \
    libapache2-mod-fcgid rt4-db-mysql rt4-apache2 request-tracker4

# Configure MySQL database
mysql -u root <<EOF
CREATE DATABASE rt4;
GRANT ALL PRIVILEGES ON rt4.* TO 'rt_user'@'localhost' IDENTIFIED BY 'rt_password';
FLUSH PRIVILEGES;
EXIT;
EOF

# Configure RT to use the database
cat <<EOL >> /etc/request-tracker4/RT_SiteConfig.pm
Set(
    \$DatabaseType, 'mysql'
);
Set(
    \$DatabaseHost, 'localhost'
);
Set(
    \$DatabasePort, ''
);
Set(
    \$DatabaseUser, 'rt_user'
);
Set(
    \$DatabasePassword, 'rt_password'
);
Set(
    \$DatabaseName, 'rt4'
);
EOL

# Initialize the database
rt-setup-database --action init --dba root --prompt-for-dba-password

# Restart services
systemctl restart apache2
systemctl enable apache2
systemctl restart mariadb
systemctl enable mariadb

# Provide completion message
echo "Request Tracker installation complete. Access it via http://$IPADDR/rt/"
