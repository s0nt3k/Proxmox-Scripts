#!/bin/bash

# Proxmox Helper Script for Debian 12 + Request Tracker (RT-5)
# This script automates the installation and configuration of RT-5 on a Debian 12 node.

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

# Update and upgrade the system
echo "Updating and upgrading the system..."
apt-get update && apt-get upgrade -y

# Install necessary dependencies
echo "Installing dependencies..."
apt-get install -y curl gnupg2 apt-transport-https ca-certificates

# Add the RT repository
echo "Adding RT repository..."
echo "deb https://download.bestpractical.com/pub/rt/debian/ bullseye main" > /etc/apt/sources.list.d/rt.list

# Import the RT GPG key
echo "Importing RT GPG key..."
curl -L https://download.bestpractical.com/pub/rt/debian/authorized_keys | apt-key add -

# Update the package list
echo "Updating package list..."
apt-get update

# Install RT and its dependencies
echo "Installing RT and its dependencies..."
apt-get install -y rt5 apache2 mariadb-server libapache2-mod-fcgid

# Configure MySQL/MariaDB
echo "Configuring MySQL/MariaDB..."
mysql_secure_installation

# Create RT database and user
echo "Creating RT database and user..."
mysql -u root -p -e "CREATE DATABASE rt5;"
mysql -u root -p -e "GRANT ALL PRIVILEGES ON rt5.* TO 'rt_user'@'localhost' IDENTIFIED BY 'Jumping4Jack@Flash';"
mysql -u root -p -e "FLUSH PRIVILEGES;"

# Configure RT
echo "Configuring RT..."
rt-setup-database --action init --dba root --prompt-for-dba-password

# Configure Apache for RT
echo "Configuring Apache for RT..."
a2enmod fcgid
a2enmod rewrite
a2dissite 000-default.conf

# Create RT Apache configuration
echo "Creating RT Apache configuration..."
cat <<EOF > /etc/apache2/sites-available/rt.conf
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /usr/share/request-tracker5/html

    AddDefaultCharset UTF-8

    <Directory /usr/share/request-tracker5/html>
        Options +ExecCGI
        AllowOverride All
        Require all granted
    </Directory>

    ScriptAlias / /usr/share/request-tracker5/html/

    <Location />
        SetHandler fcgid-script
    </Location>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

# Enable RT site and restart Apache
echo "Enabling RT site and restarting Apache..."
a2ensite rt.conf
systemctl restart apache2

# Set permissions for RT
echo "Setting permissions for RT..."
chown -R www-data:www-data /opt/rt5

# Finalize installation
echo "RT installation complete!"
echo "You can access RT at http://your-server-ip/"
echo "Default login: root / password"

exit 0
