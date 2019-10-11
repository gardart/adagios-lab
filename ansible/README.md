# Setja upp Ansible með Virtualenv og winrm stuðning

sudo yum install epel-release
sudo yum install python-devel python-setuptools python-pip krb5-devel krb5-libs krb5-workstation bind-utils
sudo pip install --upgrade pip
sudo pip install virtualenv

virtualenv venv_ansible
source venv_ansible/bin/activate
pip install ansible
#pip install molecule
pip install pywinrm
pip install pywinrm[kerberos]

# Configure hosts.ini and group_vars/windows.yml
# Test ping
ansible -i hosts.ini windows -m win_ping


