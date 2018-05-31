#! /bin/bash
sudo sed -i "s/SELINUX=enforcing/SELINUX=permissive/" /etc/selinux/config
sudo setenforce 0
sudo rpm -ihv http://opensource.is/repo/ok-release.rpm
sudo rpm -Uvh https://labs.consol.de/repo/stable/rhel7/x86_64/labs-consol-stable.rhel7.noarch.rpm
sudo yum install -y epel-release
sudo yum update -y ok-release
sudo yum clean all
sudo yum install -y git acl libstdc++-static python-setuptools pnp4nagios xinetd
sudo yum install -y nagios nagios-plugins-all
sudo yum install -y check-mk-livestatus
sudo yum --enablerepo=ok install -y adagios pynag
sudo yum --enablerepo=ok-testing install -y okconfig nagios-okplugin-check_uptime
sudo usermod -a -G nagios "$(whoami)"
sudo su - "$(whoami)"
sudo chown -R nagios:nagios /etc/nagios
sudo chmod -R 775 /etc/nagios
cd /etc/nagios/
git init
git config user.name "adagios"
git config user.email "adagios@opensource.is"
git add *
git commit -m "Initial commit"
mkdir -p /etc/nagios/adagios
pynag config --append cfg_dir=/etc/nagios/adagios
sudo chown -R nagios:nagios /etc/nagios/* /etc/nagios/.git
pynag config --append "broker_module=/usr/lib64/check_mk/livestatus.o /var/spool/nagios/cmd/livestatus"
sudo echo "ALLOWED_HOSTS = ['*']" >> /etc/adagios/adagios.conf
pynag config --set "process_performance_data=1"
sudo usermod -G apache nagios
pynag config --set 'service_perfdata_file=/var/log/pnp4nagios/service-perfdata'
pynag config --set 'service_perfdata_file_template=DATATYPE::SERVICEPERFDATA\tTIMET::$TIMET$\tHOSTNAME::$HOSTNAME$\tSERVICEDESC::$SERVICEDESC$\tSERVICEPERFDATA::$SERVICEPERFDATA$\tSERVICECHECKCOMMAND::$SERVICECHECKCOMMAND$\tHOSTSTATE::$HOSTSTATE$\tHOSTSTATETYPE::$HOSTSTATETYPE$\tSERVICESTATE::$SERVICESTATE$\tSERVICESTATETYPE::$SERVICESTATETYPE$'
pynag config --set 'service_perfdata_file_mode=a'
pynag config --set 'service_perfdata_file_processing_interval=15'
pynag config --set 'service_perfdata_file_processing_command=process-service-perfdata-file'
pynag config --set 'host_perfdata_file=/var/log/pnp4nagios/host-perfdata'
pynag config --set 'host_perfdata_file_template=DATATYPE::HOSTPERFDATA\tTIMET::$TIMET$\tHOSTNAME::$HOSTNAME$\tHOSTPERFDATA::$HOSTPERFDATA$\tHOSTCHECKCOMMAND::$HOSTCHECKCOMMAND$\tHOSTSTATE::$HOSTSTATE$\tHOSTSTATETYPE::$HOSTSTATETYPE$'
pynag config --set 'host_perfdata_file_mode=a'
pynag config --set 'host_perfdata_file_processing_interval=15'
pynag config --set 'host_perfdata_file_processing_command=process-host-perfdata-file'
pynag add command command_name=process-service-perfdata-file command_line='/bin/mv /var/log/pnp4nagios/service-perfdata /var/spool/pnp4nagios/service-perfdata.$TIMET$'
pynag add command command_name=process-host-perfdata-file command_line='/bin/mv /var/log/pnp4nagios/host-perfdata /var/spool/pnp4nagios/host-perfdata.$TIMET$'
sudo yum install -y thruk
sudo systemctl disable thruk.service
htpasswd -b /etc/nagios/passwd adagios adagios
sudo chown -R nagios:nagios /etc/nagios/* /var/log/nagios /usr/share/okconfig /etc/thruk
mkdir -p /etc/nagios/disabled
mv /etc/nagios/conf.d/check_mk_templates.cfg /etc/nagios/disabled
sudo chown -R nagios:nagios /etc/nagios/* /var/log/nagios /usr/share/okconfig /etc/thruk
sudo chmod -R 775 /etc/thruk /etc/nagios

# Configure Thruk backend
cat >>/etc/thruk/thruk_local.conf << EOF
<Component Thruk::Backend>
    <peer>
        name    = $HOSTNAME
        type    = livestatus
        <options>
            peer          = localhost:6557
        </options>
    </peer>
</Component>
EOF

# Configure livestatus for remote connections
sudo touch /etc/xinetd.d/livestatus
sudo chown nagios:nagios /etc/xinetd.d/livestatus
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
    user        = nagios
    server      = /usr/bin/unixcat
    server_args = /var/spool/nagios/cmd/livestatus
}
EOF

rm -f /etc/thruk/htpasswd
ln -s /etc/nagios/passwd /etc/thruk/htpasswd

sudo firewall-cmd --add-service=https --permanent
sudo firewall-cmd --add-service=http --permanent
sudo firewall-cmd --add-port=6557/tcp --permanent
sudo firewall-cmd --reload
sudo systemctl restart xinetd; sudo systemctl enable xinetd
sudo systemctl restart nagios; sudo systemctl enable nagios
sudo systemctl restart npcd; sudo systemctl enable npcd
sudo systemctl restart httpd; sudo systemctl enable httpd

# Add some hosts/services to Nagios with okconfig
okconfig addgroup news --alias "News web sites"
okconfig addgroup opinkerfi --alias "Opin Kerfi"
okconfig addgroup readonly --alias "Users with Read-Only Access"
okconfig addcontact guest --alias "Guest User"
okconfig addcontact adagios --alias "Adagios Admin"
okconfig addhost www.ruv.is --template http --address 104.20.39.110 --group news
okconfig addhost www.mbl.is --template http --group news
okconfig addhost www.visir.is --template http --group news
okconfig addhost www.cnn.com --template http --group news
okconfig addhost www.opinkerfi.is --template https --address 176.57.225.21 --group opinkerfi
okconfig addhost adagios-agent-01 --template linux --group opinkerfi
okconfig addhost adagios-agent-02 --template linux --group opinkerfi
sudo systemctl reload nagios

# Optional configuration
pynag list WHERE contactgroup_name='admins' and object_type=contactgroup
# Add user adagios to admins (Nagios group)
echo y | pynag update SET members=nagiosadmin,adagios WHERE contactgroup_name='admins' and object_type=contactgroup
pynag list WHERE contactgroup_name='readonly' and object_type=contactgroup
# Add user guest to readonly Nagios group
echo y | pynag update SET members=guest WHERE contactgroup_name='readonly' and object_type=contactgroup
# Reload config
sudo systemctl reload nagios

# Optional Thruk configuration - uses admins and readonly contact-groups
sudo sed -i 's|authorized_contactgroup_for_system_information=|authorized_contactgroup_for_system_information=admins|g' /etc/thruk/cgi.cfg
sudo sed -i 's|authorized_contactgroup_for_configuration_information=|authorized_contactgroup_for_configuration_information=admins|g' /etc/thruk/cgi.cfg
sudo sed -i 's|authorized_contactgroup_for_system_commands=|authorized_contactgroup_for_system_commands=admins|g' /etc/thruk/cgi.cfg
sudo sed -i 's|authorized_contactgroup_for_all_services=|authorized_contactgroup_for_all_services=admins|g' /etc/thruk/cgi.cfg
sudo sed -i 's|authorized_contactgroup_for_all_hosts=|authorized_contactgroup_for_all_hosts=admins|g' /etc/thruk/cgi.cfg
sudo sed -i 's|authorized_contactgroup_for_all_service_commands=|authorized_contactgroup_for_all_service_commands=admins|g' /etc/thruk/cgi.cfg
sudo sed -i 's|authorized_contactgroup_for_all_host_commands=|authorized_contactgroup_for_all_host_commands=admins|g' /etc/thruk/cgi.cfg
sudo sed -i 's|authorized_contactgroup_for_read_only=|authorized_contactgroup_for_read_only=readonly|g' /etc/thruk/cgi.cfg

sudo systemctl reload nagios
sudo systemctl restart httpd