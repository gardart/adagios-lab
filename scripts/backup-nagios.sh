#!/bin/bash

AGE=60
tar -C / -cf /backup/nagios-adagios-backup-$(date '+%d%b%Y').tar etc/nagios usr/share/okconfig usr/lib64/nagios usr/local/bin usr/local/sbin etc/okconfig.conf etc/adagios etc/thruk etc/httpd/conf.d
find /backup -name "nagios-adagios-backup-*.tar" -mtime +$AGE -exec rm -f {} \;

