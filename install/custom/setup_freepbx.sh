#!/bin/bash

# Proxmox VE Helper Script for Debian 12 LXC + FreePBX
# This script automates the creation of a Debian 12 LXC container and installs FreePBX.

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

# Variables
CTID="1024"                         # LXC container ID
HOSTNAME="freepbx"                  # Hostname for the container
PASSWORD="Jumping4Jack@Flash"       # Root password for the container
STORAGE="local-lvm"                 # Storage for the container (adjust as needed)
MEMORY="2048"                       # Memory in MB
SWAP="4096"                         # Swap in MB
DISK="32G"                          # Disk size
CORES="2"                           # CPU cores
IP="10.0.10.13/24"                  # IP address and subnet (adjust as needed)
GATEWAY="10.0.10.254"               # Gateway (adjust as needed)
DNS="9.9.9.9"                       # DNS server

# Create the Debian 12 LXC container
echo "Creating Debian 12 LXC container..."
pct create $CTID /var/lib/vz/template/cache/debian-12-standard_12.0-1_amd64.tar.zst \
  --hostname $HOSTNAME \
  --password $PASSWORD \
  --storage $STORAGE \
  --memory $MEMORY \
  --swap $SWAP \
  --disk $DISK \
  --cores $CORES \
  --net0 name=eth0,ip=$IP,gw=$GATEWAY \
  --nameserver $DNS \
  --unprivileged 1 \
  --features nesting=1

# Start the container
echo "Starting container..."
pct start $CTID

# Wait for the container to boot
echo "Waiting for container to boot..."
sleep 10

# Install necessary packages in the container
echo "Installing necessary packages in the container..."
pct exec $CTID -- bash -c "apt-get update && apt-get install -y curl wget gnupg2"

# Add FreePBX repository
echo "Adding FreePBX repository..."
pct exec $CTID -- bash -c "echo 'deb http://repo.freepbx.org/debian release_18 main' > /etc/apt/sources.list.d/freepbx.list"
pct exec $CTID -- bash -c "curl -o /etc/apt/trusted.gpg.d/freepbx.gpg http://repo.freepbx.org/debian/freepbx.gpg"

# Update and install FreePBX
echo "Updating and installing FreePBX..."
pct exec $CTID -- bash -c "apt-get update && apt-get install -y freepbx"

# Configure MySQL/MariaDB
echo "Configuring MySQL/MariaDB..."
pct exec $CTID -- bash -c "mysql_secure_installation"

# Configure FreePBX database
echo "Configuring FreePBX database..."
pct exec $CTID -- bash -c "amportal a ma installall"

# Restart FreePBX services
echo "Restarting FreePBX services..."
pct exec $CTID -- bash -c "fwconsole restart"

# Enable FreePBX on boot
echo "Enabling FreePBX on boot..."
pct exec $CTID -- bash -c "systemctl enable freepbx"

# Finalize installation
echo "FreePBX installation complete!"
echo "You can access FreePBX at http://$IP/"
echo "Default login: admin / admin"

exit 0
