#!/bin/bash
/usr/lib64/nagios/plugins/check_file_age /var/log/nagios/status.dat -w 300 -c 300 >/dev/null || echo "$(/etc/init.d/nagios stop; killall -9 nagios; /etc/init.d/nagios start)"

