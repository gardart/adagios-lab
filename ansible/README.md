# Setja upp Ansible með Virtualenv og winrm stuðning
# Clone
git clone --recursive https://github.com/gardart/adagios-lab.git
cd adagios-lab
git pull --recurse-submodules
git submodule update --recursive --remote


sudo yum install epel-release
sudo yum install python-devel python-setuptools python-pip krb5-devel krb5-libs krb5-workstation bind-utils gcc git
sudo pip install --upgrade pip
sudo pip install virtualenv

virtualenv venv_ansible
source venv_ansible/bin/activate
pip install -r requirements.txt
#pip install ansible
#pip install pywinrm
#pip install pywinrm[kerberos]
#ansible-galaxy install deekayen.chocolatey

# Configure hosts 
# Test ping
ansible -i hosts windows -m win_ping

# Windows AD account with winrm
sudo cp krb5.conf.d/EXAMPLE.COM.conf /etc/krb5.conf.d/

# Install Adagios agent with Ansible
git submodule update
ansible-playbook -i hosts install-adagios-agent-win.yml --limit windows

# Install with Kerberos
# ansible-playbook -i hosts install-adagios-agent-win.yml --limit windows-kerberos

# Configure windows host for WinRM
```powershell
$url = "https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"
$file = "$env:temp\ConfigureRemotingForAnsible.ps1"

(New-Object -TypeName System.Net.WebClient).DownloadFile($url, $file)

powershell.exe -ExecutionPolicy ByPass -File $file
```
