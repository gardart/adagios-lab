#! /bin/bash
sudo firewall-cmd --add-port=5666/tcp --permanent
sudo firewall-cmd --reload

# Install Nagios NRPE client with Adagios and OKconfig support
sudo yum install epel-release
sudo rpm -ihv http://opensource.is/repo/ok-release.rpm
sudo yum update -y ok-release
sudo yum install -y nagios-okconfig-nrpe --enablerepo=ok

sudo sed -i 's|allowed_hosts=127.0.0.1|allowed_hosts=127.0.0.1,0.0.0.0,adagios-server,adagios|g' /etc/nagios/nrpe.cfg
sudo sed -i 's|dont_blame_nrpe=0|dont_blame_nrpe=1|g' /etc/nagios/nrpe.cfg

sudo systemctl enable nrpe
sudo systemctl restart nrpe
