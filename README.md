# Adagios LAB on Google Cloud Platform
This LAB contains Adagios server running Nagios 4, Adagios, OKconfig, Thruk and PNP4Nagios.
The install script also uses OKconfig and pyNag to configure Nagios with some hosts, services, contactgroups and users.
Adagios project website is at http://adagios.org

# Installation
Create a project called adagios-lab-01 in GCP. Next step is to create the agents and Adagios server running on Centos 7.
This setup also installs Nagios 4, Thruk, OKconfig and PNP4Nagios.

## Adagios agents installation
Create two centos instances to work as agents that can be monitored by Adagios server 
```bash
# Create server to monitor by Adagios, with preinstalled NRPE agent - Centos 7
gcloud beta compute --project=adagios-lab-01 instances create centos7-01 --machine-type=f1-micro --tags=adagios --image=centos-7-v20180523 --image-project=centos-cloud --metadata-from-file startup-script=scripts/install-adagios-agent.sh

# Create server to monitor by Adagios, with preinstalled NRPE agent - Windows Server 2016
gcloud beta compute --project=adagios-lab-01 instances create ws2016-01 --machine-type=n1-standard-1 --tags=adagios --image=windows-server-2016-dc-v20180508 --image-project=windows-cloud --boot-disk-size=50GB --metadata-from-file windows-startup-script-ps1=scripts/install-adagios-agent.ps1
```
## Adagios server installation
```bash
gcloud beta compute --project=adagios-lab-01 instances create adagios-server --machine-type=f1-micro --tags=http-server,https-server,adagios --image=centos-7-v20180523 --image-project=centos-cloud --metadata-from-file startup-script=scripts/install-adagios-server.sh
```

## Configure the firewall for the Adagios instances
```bash
gcloud compute --project=adagios-lab-01 firewall-rules create adagios --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:5666,tcp:6557 --source-ranges=0.0.0.0/0 --target-tags=adagios
```

Next open up your browser and visit http://[adagios_server_external_ip]/adagios
