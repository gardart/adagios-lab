# Setja upp Ansible með Virtualenv og winrm stuðning

sudo yum install epel-release
sudo yum install python-devel python-setuptools python-pip krb5-devel krb5-libs krb5-workstation bind-utils gcc git
sudo pip install --upgrade pip
sudo pip install virtualenv

virtualenv venv_ansible
source venv_ansible/bin/activate
pip install ansible
#pip install molecule
pip install pywinrm
pip install pywinrm[kerberos]
#ansible-galaxy install deekayen.chocolatey

# Configure hosts 
# Test ping
ansible -i hosts.ini windows -m win_ping

# Windows AD account with winrm
sudo cp krb5.conf.d/EXAMPLE.COM.conf /etc/krb5.conf.d/

# Install Adagios agent with Ansible
git submodule update
ansible-playbook -i hosts install-adagios-agent-win.yml 

