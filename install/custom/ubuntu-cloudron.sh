#!/bin/bash

# Constants (You may need to adjust these paths/IDs)
VMID=205            # VM ID for Proxmox
VM_NAME="ubuntu-cloudron"  # VM name
STORAGE="local-lvm"  # Storage for VM disk (local-lvm is common)
ISO_PATH="/var/lib/vz/template/iso/ubuntu-24.04-server-amd64.iso"  # Path to Ubuntu 24.04 ISO
RAM="2048"           # RAM in MB
CPUS="2"             # Number of CPUs
DISK_SIZE="32"       # Disk size in GB
NET="virtio"         # Network interface type

# Step 1: Create the VM in Proxmox
echo "Creating VM $VMID with Ubuntu 24.04"
qm create $VMID --name $VM_NAME --memory $RAM --cores $CPUS --net0 virtio,bridge=vmbr0 --ide2 $STORAGE:cloudinit --cdrom $ISO_PATH --boot order=cd --sockets 1 --disk size=${DISK_SIZE}G

# Step 2: Start the VM
echo "Starting VM $VMID"
qm start $VMID

# Step 3: Wait for the VM to boot and start the Ubuntu installation (you can adjust sleep time based on your VM speed)
echo "Waiting for VM to boot and installation to complete..."
sleep 30

# Step 4: Access the VM console (Assumes you've set up your SSH keys and CloudInit properly for Ubuntu)
echo "Installing Cloudron..."

# Install dependencies for Cloudron
ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa user@<VM_IP> << 'EOF'
  sudo apt update
  sudo apt install -y curl
  curl -fsSL https://cloudron.io/cloudron_installer.sh | sudo bash
EOF

# Step 5: Setup Cloudron
echo "Cloudron installation should now be complete. Please follow the Cloudron setup instructions via browser."

# Step 6: End
echo "VM setup and Cloudron installation completed."
