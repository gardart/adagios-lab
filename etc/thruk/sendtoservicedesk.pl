#!/usr/bin/perl -w
#
###############################################################
# Program Name: sendtoservicedesk.pl               Version: 1.0
#
# Description:
# Send acknowledgement to selected unhandled Nagios host/services and email to service desk for ticket creation. 
# 
#
# Usage:
# Define Thruk action menu (host/services) 
#   {
#   "icon": "/thruk/themes/{{theme}}/images/edit.png",
#   "label": "Move to service desk",
#   "action": "server://sendtoservicedesk/$HOSTNAME$/$HOSTADDRESS$/$HOSTNOTESURL$/$HOSTBACKENDID$/$HOSTBACKENDNAME$/$HOSTBACKENDADDRESS$/$REMOTE_USER$"
#   }
# 
# Define Thruk action menu action in config
#   <action_menu_actions>
#       sendtoservicedesk = /usr/local/bin/sendtoservicedesk.pl $HOSTBACKENDADDRESS$ $HOSTBACKENDID$ $HOSTBACKENDNAME$ $HOSTNAME$ $HOSTADDRESS$ $REMOTE_USER$
#   </action_menu_actions>
#
# Author: Gardar Thorsteinsson          Date: 2018-04-04
#
#
# Revision History
#
# Version                 Date                  Who
#-------------------------------------------------------------
#
###############################################################

use strict;
use warnings;
use lib "/usr/share/thruk/lib";
use Monitoring::Livestatus;
use Data::Dumper;
use MIME::Lite;
use JSON;
use feature qw/ say /;
$Data::Dumper::Sortkeys = 1;

my $HOSTBACKENDADDRESS = $ARGV[0];
my $HOSTBACKENDID = $ARGV[1];
my $HOSTBACKENDNAME = $ARGV[2];
my $HOSTNAME = $ARGV[3];
my $HOSTADDRESS = $ARGV[4];
my $REMOTE_USER = $ARGV[5];

my $body_text = "The following problems were acknowledged:\n\n";
$body_text .= "Host: $HOSTNAME\n";
$body_text .= "Backend/Site: $HOSTBACKENDNAME\n";
$body_text .= "Acknowledged by: $REMOTE_USER\n";
$body_text .= "-----------------------------------------------------------------------------------\n";
my $body_html =    qq{
    <h3 border=\"1\"  align=\"center\">Following Problems were acknowledged</h3>
    <body>
    <TABLE cellSpacing=\"0\" cellPadding=\"0\" border=\"1\">
    <TR><TD>Host</TD><TD>Service</TD><TD>Status</TD><TD>Site</TD><TD>Status Info</TD></TR>
};

my $nl = Monitoring::Livestatus->new(
    socket            => '/var/spool/nagios/cmd/livestatus',
);

# Other method using nagios server address
#my $nl = Monitoring::Livestatus->new(
#                                     peer             => $HOSTBACKENDADDRESS,
#                                     #timeout          => 5,
#                                     #keepalive        => 1,
#);

my $hosts = $nl->selectall_arrayref("GET hosts\nColumns: name address plugin_output\nFilter: name = $HOSTNAME\nFilter: state != 0\nFilter: acknowledged != 1", { Slice => {} });
my $services = $nl->selectall_arrayref("GET services\nColumns: host_name service_description state host_address plugin_output\nFilter: host_name = $HOSTNAME\nFilter: state != 0\nFilter: acknowledged != 1", { Slice => {} });

print Dumper($hosts);
print Dumper($services);

my $hostproblems = scalar @{$hosts};
my $serviceproblems = scalar @{$services};
my $problems_total = $hostproblems + $serviceproblems;
for my $host (@{$hosts}) {
    # ACKNOWLEDGE_HOST_PROBLEM;<host_name>;<sticky>;<notify>;<persistent>;<author>;<comment>
    $nl->do(sprintf("COMMAND [%d] ACKNOWLEDGE_HOST_PROBLEM;%s;1;1;1;1;%s;Email sent to service desk", time(), $HOSTNAME, $REMOTE_USER));
    # Body Text message
    $body_text .= sprintf("Host Problem: %s\n", $host->{'plugin_output'});
    $body_text .= "-----------------------------------------------------------------------------------\n\n";
}
    $body_text .= " Service Problems                                                                  \n\n";
    $body_text .= "-----------------------------------------------------------------------------------\n\n";
for my $service (@{$services}) {
    $body_html .= qq{<TR><TD>$service->{'host_name'}</TD><TD>$service->{'service_description'}</TD><TD>$service->{'state'}</TD><TD>$HOSTBACKENDNAME</TD><TD>$service->{'plugin_output'}</TD></TR>
    };
    # Body Text message
    $body_text .= sprintf("Service: %s\n", $service->{'service_description'});
    $body_text .= sprintf("Status Information: %s\n", $service->{'plugin_output'});
    $body_text .= sprintf("State: %s\n", $service->{'state'});

    $body_text .= "-----------------------------------------------------------------------------------\n\n";
    # Send Ack service command to livestatus socket
    #ACKNOWLEDGE_SVC_PROBLEM;<host_name>;<service_description>;<sticky>;<notify>;<persistent>;<author>;<comment>
    $nl->do(sprintf("COMMAND [%d] ACKNOWLEDGE_SVC_PROBLEM;%s;%s;1;1;1;%s;Email sent to service desk", time(), $HOSTNAME, $service->{'service_description'}, $REMOTE_USER ));
}

# Close HTML Table
$body_html .= qq{</TABLE>};
$body_text .= "For more information regarding services on this host, click the link below:\n";
$body_text .= "https://$HOSTBACKENDNAME/thruk/#cgi-bin/status.cgi?hidesearch=2&s0_op=%7E&s0_type=search&add_default_service_filter=1&s0_value=$HOSTNAME";
#$body_text .= "\n\nMore info for host on Sysvik:\n";
#$body_text .= "https://www.sysvik.com/go/ip=$HOSTNAME";
#$body_text .= "\n\nIf you can't find the hostname on Sysvik, try searching for ip address instead:\n";
#$body_text .= "https://www.sysvik.com/go/$HOSTADDRESS";

################################################
#
#       Send Email to service desk mail
#

my $email = 'helpdesk@example.com';
my $subject = sprintf('Nagios Monitoring - %s', $HOSTNAME);
# # create a new MIME Lite based email
my $msg = MIME::Lite->new
(
Subject => $subject,
From    => 'nagios@example.com',
To      => $email,
Type    => 'text/plain',
Data    => $body_text
);
#print $problems_total;
if ($problems_total >= 1) {
    print "Message sent\n";
    $msg->send();
} else {print "No problems found\n"}
