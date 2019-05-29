#!/bin/bash
# sh notification_teams.sh -a "ACKNOWLEDGEMENT" -b "monitoring-server" -e "Testservice" -f "OK" -g "servout" -z "https://outlook.office.com/webhook/xxxxxxx/IncomingWebhook/"

while getopts 'a:b:c:d:e:f:g:y:z:' opt ; do
  case $opt in
    a) NOTIFICATIONTYPE=$OPTARG ;;
    b) HOSTNAME=$OPTARG ;;
    c) HOSTSTATE=$OPTARG ;;
    d) HOSTOUTPUT=$OPTARG ;;
    e) SERVICEDESC=$OPTARG ;;
    f) SERVICESTATE=$OPTARG ;;
    g) SERVICEOUTPUT=$OPTARG ;;
    z) WEBHOOK_PATH=$OPTARG ;;
  esac
done

MONITORING_URL="https://ver-monitor-01.okh.is"
WEBHOOK_ADDRESS="${WEBHOOK_PATH}"


if [ -x $HOSTSTATE ]; then

  if [ "$NOTIFICATIONTYPE" = "ACKNOWLEDGEMENT" ]; then
    ICON="&#x1F4DD;" # :memo:
  elif [ "$SERVICESTATE" = "CRITICAL" ]; then
    ICON="&#x26D4;" # :no_entry:
  elif [ "$SERVICESTATE" = "WARNING" ]; then
    ICON="&#x26A0;" # :warning:
  elif [ "$SERVICESTATE" = "OK" ]; then
    ICON="&#x2705;" # :white_check_mark:
  elif [ "$SERVICESTATE" = "UNKNOWN" ]; then
    ICON="&#x003F;" # :question:
  else
    ICON="&#x25FB" # :white_medium_square:
  fi

  MESSAGE="${ICON} *[${NOTIFICATIONTYPE}]* *<${MONITORING_URL}/#cgi-bin/status.cgi?host=${HOSTNAME}|${HOSTNAME}>* service <${MONITORING_URL}/#cgi-bin/extinfo.cgi?type=2&host=${HOSTNAME}&service=${SERVICEDESC}|${SERVICEDESC}> is *${SERVICESTATE}*\n_${SERVICEOUTPUT}_"

else

  if [ "$HOSTSTATE" = "UP" ]; then
    ICON="&#x2705;" # :white_check_mark:
  elif [ "$HOSTSTATE" = "DOWN" ]; then
    ICON="&#x26D4;" # :no_entry:
  elif [ "$HOSTSTATE" = "UNREACHABLE" ]; then
    ICON="&#x26A0;" # :warning:
  else
    ICON="&#x25FB" # :white_medium_square:
  fi

  MESSAGE="${ICON} *[${NOTIFICATIONTYPE}]* *<${MONITORING_URL}/#cgi-bin/status.cgi?host=${HOSTNAME}|${HOSTNAME}>* is *${HOSTSTATE}*\n_${HOSTOUTPUT}_"

fi

curl $WEBHOOK_ADDRESS --header 'Content-Type: application/json' --data "{ \"Text\": \"${MESSAGE}\", \"TextFormat\" : \"markdown\", \"Title\" : \"Nagios\"}"

