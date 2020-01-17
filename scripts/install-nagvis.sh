# Install Nagvis
sudo yum install -y php-mbstring graphviz graphviz-php graphviz-gd php php-gd php-gettext php-session php-xml php-pdo
cd /tmp/
wget http://www.nagvis.org/share/nagvis-1.9.17.tar.gz
tar -zxvf nagvis-1.9.17.tar.gz
cd nagvis-1.9.17

# Install Nagvis with demo maps
sudo ./install.sh -s nagios -n /etc/nagios -p /usr/local/nagvis -u apache -g apache -w /etc/httpd/conf.d -i mklivestatus -l unix:/var/spool/nagios/cmd/livestatus -a y -q

# Install Nagvis without demo maps
#./install.sh -s nagios -n /etc/nagios -p /usr/local/nagvis -u apache -g apache -w /etc/httpd/conf.d -i mklivestatus -l unix:/var/spool/nagios/cmd/livestatus -o -a y -q

sudo systemctl reload httpd
