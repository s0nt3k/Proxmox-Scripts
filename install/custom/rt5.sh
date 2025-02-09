#!/bin/bash

# Proxmox Helper Script for Request Tracker 5 (RT5) Setup
# Ensure this script is run as root or with sudo privileges

# Variables
RT_VERSION="5.0.0"  # Change this to the desired RT version
DB_NAME="rt5"
DB_USER="rt_user"
DB_PASS="rt_password"  # Change this to a secure password
RT_SITE_NAME="My RT Site"
RT_ORG_NAME="My Organization"
RT_WEB_DOMAIN="rt.example.com"  # Change this to your domain

# Update and install dependencies
echo "Updating system and installing dependencies..."
apt-get update
apt-get install -y apache2 mariadb-server libapache2-mod-fcgid \
    libapache2-mod-perl2 build-essential curl gcc make \
    libssl-dev libgd-graph-perl liburi-perl libhtml-format-perl \
    libhtml-tree-perl libtext-template-perl libdatetime-perl \
    libmailtools-perl libmime-tools-perl libdbd-mysql-perl \
    libapache-session-perl libcgi-pm-perl libhtml-scrubber-perl \
    libjson-perl libxml-rss-perl libcrypt-eksblowfish-perl \
    libdatetime-format-mail-perl libdatetime-format-mysql-perl \
    libdatetime-format-pg-perl libdatetime-format-strptime-perl \
    libdatetime-format-iso8601-perl libdatetime-format-natural-perl \
    libdatetime-timezone-perl libemail-address-perl libfile-slurp-perl \
    liblocale-maketext-lexicon-perl liblog-dispatch-perl libmime-types-perl \
    libnet-cidr-perl libnet-ip-perl libplack-perl librole-basic-perl \
    libscope-upper-perl libstring-shellquote-perl libterm-readkey-perl \
    libtext-password-pronounceable-perl libtext-wrapper-perl \
    libtree-simple-perl libuniversal-require-perl libwww-perl \
    libxml-simple-perl libyaml-perl

# Install CPAN modules
echo "Installing required CPAN modules..."
cpan -i Module::Install
cpan -i DateTime::Format::Natural
cpan -i HTML::FormatText::WithLinks
cpan -i HTML::FormatText::WithLinks::AndTables
cpan -i HTML::Scrubber
cpan -i Locale::Maketext::Lexicon
cpan -i Log::Dispatch
cpan -i MIME::Tools
cpan -i Plack::Handler::FCGI
cpan -i Scope::Upper
cpan -i Text::Password::Pronounceable
cpan -i Text::Wrapper
cpan -i Tree::Simple
cpan -i UNIVERSAL::require
cpan -i XML::RSS

# Configure MariaDB
echo "Configuring MariaDB..."
mysql -e "CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# Download and extract Request Tracker
echo "Downloading Request Tracker ${RT_VERSION}..."
cd /opt
curl -O https://download.bestpractical.com/pub/rt/release/rt-${RT_VERSION}.tar.gz
tar -xvzf rt-${RT_VERSION}.tar.gz
cd rt-${RT_VERSION}

# Configure RT
echo "Configuring Request Tracker..."
./configure --with-web-user=www-data --with-web-group=www-data \
    --with-db-type=mysql --with-db-host=localhost --with-db-name=${DB_NAME} \
    --with-db-user=${DB_USER} --with-db-pass=${DB_PASS}

# Install RT
echo "Installing Request Tracker..."
make install
make initialize-database

# Configure Apache for RT
echo "Configuring Apache for Request Tracker..."
cat > /etc/apache2/sites-available/rt.conf <<EOF
<VirtualHost *:80>
    ServerName ${RT_WEB_DOMAIN}
    DocumentRoot /opt/rt5/share/html

    <Directory /opt/rt5/share/html>
        Require all granted
        Options +ExecCGI
        AddHandler fcgid-script .fcgi
    </Directory>

    ScriptAlias / /opt/rt5/sbin/rt-server.fcgi/

    ErrorLog \${APACHE_LOG_DIR}/rt_error.log
    CustomLog \${APACHE_LOG_DIR}/rt_access.log combined
</VirtualHost>
EOF

# Enable the RT site and required modules
a2ensite rt.conf
a2enmod fcgid
a2enmod rewrite
systemctl restart apache2

# Set permissions
echo "Setting permissions..."
chown -R www-data:www-data /opt/rt5

# Output completion message
echo "Request Tracker ${RT_VERSION} setup is complete!"
echo "Access your RT instance at http://${RT_WEB_DOMAIN}"
echo "Default admin credentials: root / password"
