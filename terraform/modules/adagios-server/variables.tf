# variables.tf
variable "name"              { default = "adagios-server-02"}
variable "google_project_id" { default = "adagios-lab-01" }
variable "account_file"      { default = "~/.gcp/account.json" }
variable "region" 	     { default = "us-east1" }
variable "zone" 	     { default = "us-east1-b" }
variable "tags" 	     { default = ["adagios-server", "adagios-agent"] }
variable "image" 	     { default = "centos-7-v20180523" }
variable "machine_type"      { default = "n1-standard-1" }

