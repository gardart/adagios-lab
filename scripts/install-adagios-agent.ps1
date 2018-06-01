Set-ExecutionPolicy Bypass -Scope Process -Force

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Invoke-WebRequest -Uri "https://github.com/gardart/nagios-nsclient-install/archive/master.zip" -outfile "$env:TEMP\master.zip" -Verbose

Expand-Archive -Path "$env:TEMP\master.zip" -DestinationPath "$env:TEMP" -Force -Verbose

. $env:TEMP\nagios-nsclient-install-master\Deploy-Application.ps1
