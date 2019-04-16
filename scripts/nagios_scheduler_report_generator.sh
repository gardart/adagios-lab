pynag_cmd='pynag config --get'

echo "Nagios Health"
/usr/lib64/nagios/plugins/check_nagios_proc
echo "\n"
echo "Host check latency > 1 sec"
pynag livestatus --get hosts --columns "alias execution_time latency" --filter "latency > 1" | awk 'NR == 1; NR > 1 {print $0 | "sort -n -r -k3"}'

echo "Host check execution time > 5 sec"
pynag livestatus --get hosts --columns "alias execution_time latency" --filter "execution_time > 5" | awk 'NR == 1; NR > 1 {print $0 | "sort -n -r -k2"}'

echo "Service check latency > 1 sec"
pynag livestatus --get services --columns "host_name execution_time latency description" --filter "latency > 1" | awk 'NR == 1; NR > 1 {print $0 | "sort -n -r -k3"}'

echo "Service check execution time > 5 sec"
pynag livestatus --get services --columns "host_name execution_time latency description" --filter "execution_time > 5"| awk 'NR == 1; NR > 1 {print $0 | "sort -n -r -k2"}'

echo "Program wide performance information"
nagiostats

echo ---------------------------------------------
echo nagios.cfg settings
echo
echo Scheduler settings
echo ---------------------------------------------
echo max_service_check_spread=$($pynag_cmd max_service_check_spread)
echo service_interleave_factor=$($pynag_cmd service_interleave_factor)
echo service_inter_check_delay_method=$($pynag_cmd service_inter_check_delay_method)
echo max_host_check_spread=$($pynag_cmd max_host_check_spread)
echo host_inter_check_delay_method=$($pynag_cmd host_inter_check_delay_method)
echo max_concurrent_checks=$($pynag_cmd max_concurrent_checks)
echo check_result_reaper_frequency=$($pynag_cmd check_result_reaper_frequency)
echo max_check_result_reaper_time=$($pynag_cmd max_check_result_reaper_time)
echo max_check_result_file_age=$($pynag_cmd max_check_result_file_age)
echo cached_host_check_horizon=$($pynag_cmd cached_host_check_horizon)
echo cached_service_check_horizon=$($pynag_cmd cached_service_check_horizon)
echo 
echo Rescheduling settings
echo ---------------------------------------------
echo auto_reschedule_checks=$($pynag_cmd auto_reschedule_checks)
echo auto_rescheduling_interval=$($pynag_cmd auto_rescheduling_interval)
echo auto_rescheduling_window=$($pynag_cmd auto_rescheduling_window)
echo
echo Timeout settings
echo ---------------------------------------------
echo sleep_time=$($pynag_cmd sleep_time)
echo service_check_timeout=$($pynag_cmd service_check_timeout)
echo host_check_timeout=$($pynag_cmd host_check_timeout)
echo event_handler_timeout=$($pynag_cmd event_handler_timeout)
echo notification_timeout=$($pynag_cmd notification_timeout)
echo ocsp_timeout=$($pynag_cmd ocsp_timeout)
echo perfdata_timeout=$($pynag_cmd perfdata_timeout)
echo
echo Retention
echo ---------------------------------------------
echo use_retained_program_state=$($pynag_cmd use_retained_program_state)
echo use_retained_scheduling_info=$($pynag_cmd use_retained_scheduling_info)
echo
echo Other settings
echo ---------------------------------------------
echo use_aggressive_host_checking=$($pynag_cmd use_aggressive_host_checking)
echo use_large_installation_tweaks=$($pynag_cmd use_large_installation_tweaks)
echo debug_level=$($pynag_cmd debug_level)
echo
echo Interval
echo ---------------------------------------------
echo interval_length=$($pynag_cmd interval_length)
echo command_check_interval=$($pynag_cmd command_check_interval)
echo ---------------------------------------------

echo File Descriptors in Kernel Memory
echo ---------------------------------------------
echo $(/sbin/sysctl fs.file-nr)
echo ---------------------------------------------

echo Running Nagios Processes
echo ---------------------------------------------
echo $(ps -C nagios -o user,ppid,pid,start_time,stat,cmd --no-headers)
echo ---------------------------------------------

echo Installed Packages
echo ---------------------------------------------
rpm -qa
echo ---------------------------------------------

echo ---------------------------------------------
echo THE END
echo ---------------------------------------------

