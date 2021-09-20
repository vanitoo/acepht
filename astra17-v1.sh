
sudo mount /dev/sdb1 /srv/ftp/iso/
sudo mount /srv/ftp/iso/astra17.iso /srv/ftp/repo/astra17
sudo mount /srv/ftp/iso/astra17-devel-1.iso /srv/ftp/repo/astra17-devel-1
sudo mount /srv/ftp/iso/astra17-devel-2.iso /srv/ftp/repo/astra17-devel-2

sudo mcedit /etc/apt/sources.list
deb ftp://adm/repo/astra17 1.7_x86-64 contrib main non-free
deb ftp://adm/repo/astra17-devel-1 1.7_x86-64 contrib main non-free
deb ftp://adm/repo/astra17-devel-2 1.7_x86-64 contrib main non-free

sudo sh -c "echo 'nameserver 8.8.8.8' sudo >> /etc/resolv.conf"

sudo sh -c "echo 'deb http://ppa.launchpad.net/ansible/ansible/ubuntu focal main' > /etc/apt/sources.list.d/ansible.list"
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367

sudo apt update; sudo apt install ansible git sshpass python-pip


ssh-keygen -b 4096 -t rsa -f /home/$(whoami)/.ssh/id_rsa -N ""

sudo tee -a remote-hosts<<EOF
node1
node2
node3
EOF

ssh-keyscan -f ./remote-hosts >> ~/.ssh/known_hosts

sshpass -p 12345678 ssh-copy-id $(whoami)@node1
sshpass -p 12345678 ssh-copy-id $(whoami)@node2
sshpass -p 12345678 ssh-copy-id $(whoami)@node3


>>>node 1-3
sudo tee -a /etc/apt/sources.list<<EOF
deb ftp://adm/repo/astra17 1.7_x86-64 contrib main non-free
deb ftp://adm/repo/astra17-devel-1 1.7_x86-64 contrib main non-free
deb ftp://adm/repo/astra17-devel-2 1.7_x86-64 contrib main non-free
EOF


git clone https://github.com/ceph/ceph-ansible
cd ceph-ansible; git checkout stable-4.0
sudo pip install -r requirements.txt


***

mcedit inventory_hosts
[mons]
192.168.11.91
192.168.11.92
192.168.11.93
 
[osds]
192.168.11.91
192.168.11.92
192.168.11.93
 
[mgrs]
192.168.11.91
192.168.11.92
192.168.11.93
 
[grafana-server]
192.168.11.91
192.168.11.92
192.168.11.93

[all:vars]
ansible_python_interpreter=/usr/bin/python3

***

sudo apt install chrony


cp site.yml.sample site.yml
mcedit site.yml
добавить
ignore_errors: true

cp group_vars/all.yml.sample group_vars/all.yml


mcedit roles/ceph-validate/tasks/check_system.yml
изменить строку
when: ansible_facts['os_family'] not in ['Astra Linux', 'Debian', 'RedHat', 'ClearLinux', 'Suse']



ansible-playbook ./site.yml -i ./inventory_hosts -K





