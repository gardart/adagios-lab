# If you don't know how to configure SElinux, put it in permissive mode:
sudo sed -i "s/SELINUX=enforcing/SELINUX=permissive/" /etc/selinux/config
sudo setenforce 0

# First install the opensource.is and consol labs repositories
sudo rpm -ihv http://opensource.is/repo/ok-release.rpm
sudo rpm -Uvh https://labs.consol.de/repo/stable/rhel7/x86_64/labs-consol-stable.rhel7.noarch.rpm
sudo yum update -y ok-release

# Centos users need to install the epel repositories (fedora users skip this step)
sudo yum install -y epel-release

# Install Naemon / Thruk
sudo yum install -y naemon xinetd

# Install Adagios and other needed packages
sudo yum install -y git acl pnp4nagios python-setuptools python2-django16 vim net-tools
sudo yum --enablerepo=ok-testing install -y adagios okconfig nagios-okplugin-crit2warn

# Now all the packages have been installed, and we need to do a little bit of
# configuration before we start doing awesome monitoring

# Lets make sure adagios can write to naemon configuration files, and that
# it is a valid git repo so we have audit trail

sudo usermod -a -G naemon "$(whoami)"
sudo su - "$(whoami)"
sudo chown -R naemon:naemon /etc/naemon
sudo chmod -R 775 /etc/naemon
cd /etc/naemon/
git init
git config user.name "adagios"
git config user.email "adagios@opensource.is"
git add *
git commit -m "Initial commit"

# Fix permissions for naemon and pnp4nagios
sudo chgrp naemon /etc/pnp4nagios/process_perfdata.cfg
sudo chown naemon:naemon -R /etc/adagios
sudo chown naemon:naemon /var/lib/adagios /var/lib/pnp4nagios /var/spool/pnp4nagios
sudo chown -R naemon:root /var/log/okconfig /var/log/pnp4nagios
sudo setfacl -R -m group:naemon:rwx -m d:group:naemon:rwx 	/etc/naemon/ /etc/adagios /var/lib/adagios /var/lib/pnp4nagios /var/spool/pnp4nagios
sudo setfacl -R -m user:naemon:rwx -m d:user:naemon:rwx /var/log/okconfig /var/log/pnp4nagios


# Make sure nagios doesn't interfere
sudo mkdir /etc/nagios/disabled
sudo mv /etc/nagios/{nagios,cgi}.cfg /etc/nagios/disabled/

# Make objects created by adagios go to /etc/naemon/adagios
mkdir -p /etc/naemon/adagios
pynag config --append cfg_dir=/etc/naemon/adagios

# Make adagios naemon aware
sudo sed -i '
    s|/etc/nagios/passwd|/etc/thruk/htpasswd|g
    s|user=nagios|user=naemon|g
    s|group=nagios|group=naemon|g' /etc/httpd/conf.d/adagios.conf

sudo sed -i '
    s|/etc/nagios/nagios.cfg|/etc/naemon/naemon.cfg|g
    s|nagios_url = "/nagios|nagios_url = "/thruk|g
    s|/etc/nagios/adagios/|/etc/naemon/adagios/|g
    s|/etc/init.d/nagios|/etc/init.d/naemon|g
    s|nagios_service = "nagios"|nagios_service = "naemon"|g
    s|livestatus_path = None|livestatus_path = "/var/cache/naemon/live"|g
    s|/usr/sbin/nagios|/usr/bin/naemon|g' /etc/adagios/adagios.conf

# Make okconfig naemon aware

sudo sed -i '
    s|/etc/nagios/nagios.cfg|/etc/naemon/naemon.cfg|g
    s|/etc/nagios/okconfig/|/etc/naemon/okconfig/|g
    s|/usr/share/okconfig/templates|/etc/naemon/okconfig/templates|g
    s|/etc/nagios/okconfig/examples|/etc/naemon/okconfig/examples|g' /etc/okconfig.conf

sudo mkdir -p /etc/naemon/okconfig/{templates,examples}
sudo cp -r /usr/share/okconfig/templates/* /etc/naemon/okconfig/templates/
sudo cp -r /usr/share/okconfig/examples/* /etc/naemon/okconfig/examples/

#sudo okconfig init
sudo okconfig verify

# Add naemon to apache group so it has permissions to pnp4nagios's session files
sudo usermod -G apache naemon

# Allow Adagios to control the service
sudo sed -i '
    s|nagios|naemon|g
    s|/usr/sbin/naemon|/usr/bin/naemon|g' /etc/sudoers.d/adagios

# A list of strings representing the host/domain names that this Django site can
# serve. This is a security measure to prevent HTTP Host header attacks
#sudo echo "ALLOWED_HOSTS = ['*']" >> /etc/adagios/adagios.conf

# Make naemon use nagios plugins, more people are doing it like that.
sed -i 's|/usr/lib64/naemon/plugins|/usr/lib64/nagios/plugins|g' /etc/naemon/resource.cfg

# Configure pnp4nagios
sudo sed -i 's|/etc/nagios/passwd|/etc/thruk/htpasswd|g' /etc/httpd/conf.d/pnp4nagios.conf
sudo sed -i '
	s/user = nagios/user = naemon/g
	s/group = nagios/group = naemon/g' /etc/pnp4nagios/npcd.cfg

# Enable Naemon performance data
pynag config --set "process_performance_data=1"

# service performance data
pynag config --set 'service_perfdata_file=/var/lib/naemon/service-perfdata'
pynag config --set 'service_perfdata_file_template=DATATYPE::SERVICEPERFDATA\tTIMET::$TIMET$\tHOSTNAME::$HOSTNAME$\tSERVICEDESC::$SERVICEDESC$\tSERVICEPERFDATA::$SERVICEPERFDATA$\tSERVICECHECKCOMMAND::$SERVICECHECKCOMMAND$\tHOSTSTATE::$HOSTSTATE$\tHOSTSTATETYPE::$HOSTSTATETYPE$\tSERVICESTATE::$SERVICESTATE$\tSERVICESTATETYPE::$SERVICESTATETYPE$'
pynag config --set 'service_perfdata_file_mode=a'
pynag config --set 'service_perfdata_file_processing_interval=15'
pynag config --set 'service_perfdata_file_processing_command=process-service-perfdata-file'

# host performance data
pynag config --set 'host_perfdata_file=/var/lib/naemon/host-perfdata'
pynag config --set 'host_perfdata_file_template=DATATYPE::HOSTPERFDATA\tTIMET::$TIMET$\tHOSTNAME::$HOSTNAME$\tHOSTPERFDATA::$HOSTPERFDATA$\tHOSTCHECKCOMMAND::$HOSTCHECKCOMMAND$\tHOSTSTATE::$HOSTSTATE$\tHOSTSTATETYPE::$HOSTSTATETYPE$'
pynag config --set 'host_perfdata_file_mode=a'
pynag config --set 'host_perfdata_file_processing_interval=15'
pynag config --set 'host_perfdata_file_processing_command=process-host-perfdata-file'

pynag add command command_name=process-service-perfdata-file command_line='/bin/mv /var/lib/naemon/service-perfdata /var/spool/pnp4nagios/service-perfdata.$TIMET$'
pynag add command command_name=process-host-perfdata-file command_line='/bin/mv /var/lib/naemon/host-perfdata /var/spool/pnp4nagios/host-perfdata.$TIMET$'

pynag config --append cfg_dir=/etc/naemon/commands/

# Reset password for Thruk/Naemon admin user
sudo htpasswd -b /etc/thruk/htpasswd adagios adagios

# Disable OMD thruk service
sudo systemctl disable thruk.service
sudo mv /etc/httpd/conf.d/thruk_cookie_auth_vhost.conf /etc/httpd/conf.d/thruk_cookie_auth_vhost.conf.disabled
sudo touch /etc/httpd/conf.d/thruk_cookie_auth_vhost.conf


# Configure livestatus for remote connections
sudo touch /etc/xinetd.d/livestatus
sudo chown naemon:naemon /etc/xinetd.d/livestatus
sudo chmod 775 /etc/xinetd.d/livestatus

cat >/etc/xinetd.d/livestatus << EOF
service livestatus
{
    type        = UNLISTED
    socket_type = stream
    protocol    = tcp
    wait        = no

    # limit to 100 connections per second. Disable 3 secs if above.
    cps             = 1000 3

    # set the number of maximum allowed parallel instances of unixcat.
    instances       = 500

    # limit the maximum number of simultaneous connections from
    # one source IP address
    per_source      = 500

    # Disable TCP delay, makes connection more responsive
    flags           = NODELAY

    # Disable this services
    disable     = no

    # TCP port number.
    port        = 6557

    # Paths and users.
    user        = naemon
    server      = /usr/bin/unixcat
    server_args = /var/cache/naemon/live
}
EOF

# Allow connections through the firewall on port 80 and 443
sudo firewall-cmd --add-service=https --permanent
sudo firewall-cmd --add-service=http --permanent
sudo firewall-cmd --add-port=6557/tcp --permanent
sudo firewall-cmd --reload

# Enable and restart services
sudo systemctl restart xinetd; sudo systemctl enable xinetd
sudo systemctl restart naemon; sudo systemctl enable naemon
sudo systemctl restart npcd; sudo systemctl enable npcd
sudo systemctl restart httpd; sudo systemctl enable httpd

# Install nagios plugins
sudo yum install -y nagios-plugins-all

# Install nagios plugins from Opin Kerfi (nagios-okplugin)
sudo yum install -y nagios-okplugin-*

# Add some hosts/services to Nagios with okconfig
okconfig addgroup news --alias "News web sites"
okconfig addgroup opinkerfi --alias "Opin Kerfi"
okconfig addgroup readonly --alias "Users with Read-Only Access"
okconfig addgroup default --alias "Default Group"
#okconfig addcontact thrukadmin --alias "Thruk Admin"
okconfig addcontact guest --alias "Guest User"
okconfig addcontact adagios --alias "Adagios Admin"
okconfig addhost www.ruv.is --template http --address 104.20.39.110 --group news
okconfig addhost www.mbl.is --template http --group news
okconfig addhost www.visir.is --template http --group news
okconfig addhost www.cnn.com --template http --group news
okconfig addhost www.opinkerfi.is --template https --address 176.57.225.21 --group opinkerfi
okconfig addhost centos7-01 --template linux --group opinkerfi
okconfig addhost ws2016-01 --template windows --group opinkerfi
sudo systemctl reload naemon

# Optional configuration
pynag list WHERE contactgroup_name='admins' and object_type=contactgroup
# Add user adagios to admins (Nagios group)
echo y | pynag update SET members=naemonadmin,adagios WHERE contactgroup_name='admins' and object_type=contactgroup
pynag list WHERE contactgroup_name='readonly' and object_type=contactgroup
# Add user guest to readonly Nagios group
echo y | pynag update SET members=guest WHERE contactgroup_name='readonly' and object_type=contactgroup
# Reload config
sudo systemctl reload naemon

# Optional Thruk configuration - uses admins and readonly contact-groups
sudo sed -i 's|authorized_contactgroup_for_system_information=|authorized_contactgroup_for_system_information=admins|g' /etc/thruk/cgi.cfg
sudo sed -i 's|authorized_contactgroup_for_configuration_information=|authorized_contactgroup_for_configuration_information=admins|g' /etc/thruk/cgi.cfg
sudo sed -i 's|authorized_contactgroup_for_system_commands=|authorized_contactgroup_for_system_commands=admins|g' /etc/thruk/cgi.cfg
sudo sed -i 's|authorized_contactgroup_for_all_services=|authorized_contactgroup_for_all_services=admins|g' /etc/thruk/cgi.cfg
sudo sed -i 's|authorized_contactgroup_for_all_hosts=|authorized_contactgroup_for_all_hosts=admins|g' /etc/thruk/cgi.cfg
sudo sed -i 's|authorized_contactgroup_for_all_service_commands=|authorized_contactgroup_for_all_service_commands=admins|g' /etc/thruk/cgi.cfg
sudo sed -i 's|authorized_contactgroup_for_all_host_commands=|authorized_contactgroup_for_all_host_commands=admins|g' /etc/thruk/cgi.cfg
sudo sed -i 's|authorized_contactgroup_for_read_only=|authorized_contactgroup_for_read_only=readonly|g' /etc/thruk/cgi.cfg

sudo systemctl reload naemon
sudo systemctl restart httpd

# Postfix
sudo postfix flush
sudo postsuper -d ALL
#sudo sed -i 's|\#relayhost = \[gateway.my.domain\]|relayhost \= \[mail.server.is\]|g' /etc/postfix/main.cf
sudo systemctl enable postfix
sudo systemctl restart postfix
