# astra linux 1.7 + ceph14 + ansible
# версия Андрей
#
# конф для 3 нод + 1 админский
# сеть везде настроена
# диск с дистрибами подключен к adm


## на adm
# монтируем образы в папку FTP
sudo -i
sudo mount /dev/sdb1 /srv/ftp/iso/
sudo mount /srv/ftp/iso/astra17.iso /srv/ftp/repo/astra17
sudo mount /srv/ftp/iso/astra17-devel-1.iso /srv/ftp/repo/astra17-devel-1
sudo mount /srv/ftp/iso/astra17-devel-2.iso /srv/ftp/repo/astra17-devel-2



## на всех 
sudo -i
passwd

sudo tee /etc/hosts<<EOF
127.0.0.1      localhost

192.168.11.90  adm
192.168.11.91  node1
192.168.11.92  node2
192.168.11.93  node3
EOF

sudo sh -c "echo 'nameserver 8.8.8.8' sudo > /etc/resolv.conf"

sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/#g' /etc/ssh/sshd_config
systemctl restart ssh

# везде ... прописываем пути обновлений
sudo tee /etc/apt/sources.list<<EOF
deb ftp://adm/repo/astra17 1.7_x86-64 contrib main non-free
deb ftp://adm/repo/astra17-devel-1 1.7_x86-64 contrib main non-free
deb ftp://adm/repo/astra17-devel-2 1.7_x86-64 contrib main non-free
EOF

# везде
ssh-keygen

# на сервере
KEY=$(sudo cat /root/.ssh/id_rsa.pub)
ssh root@node1 "bash -c \"echo $KEY >> /root/.ssh/authorized_keys\""
ssh root@node2 "bash -c \"echo $KEY >> /root/.ssh/authorized_keys\""
ssh root@node3 "bash -c \"echo $KEY >> /root/.ssh/authorized_keys\""


# везде
sudo apt update; sudo apt install git -y

git clone https://github.com/vanitoo/acepht.git

cp /etc/debian_version /etc/debian_version.old
cp /etc/issue /etc/issue.old
cp /etc/issue.net /etc/issue.net.old
cp /etc/locale.alias /etc/locale.alias.old
cp /etc/profile /etc/profile.old
cp /usr/lib/os-release /usr/lib/os-release.old

cp ./acepht/v4/debian_version /etc/debian_version
cp ./acepht/v4/issue /etc/issue
cp ./acepht/v4/issue.net /etc/issue.net
cp ./acepht/v4/locale.alias /etc/locale.alias
cp ./acepht/v4/profile /etc/profile
cp ./acepht/v4/os-release /usr/lib/os-release


#на сервер
apt install ca-certificates ansible git python-pip python3-apt python-apt ceph -y

#на нодах # везде
apt install ca-certificates ceph python3-apt python-apt -y

sudo systemctl enable ntp; sudo systemctl start ntp


cd /usr/lib/python3/dist-packages
sudo ln -s apt_inst.cpython-37m-x86_64-linux-gnu.so apt_inst.so
sudo ln -s apt_pkg.cpython-37m-x86_64-linux-gnu.so apt_pkg.so

sudo sh -c "echo 'deb https://mirror.yandex.ru/debian/ buster main contrib non-free' sudo >> /etc/apt/sources.list"
sudo sed -i 's/deb ftp/#deb ftp/#g' /etc/apt/sources.list

sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 04EE7237B7D453EC
sudo apt update; sudo apt install software-properties-common -y


**

# на сервере
git clone https://github.com/ceph/ceph-ansible
cd ceph-ansible
git checkout stable-4.0
pip install -r requirements.txt

# везде
sudo sed -i 's/deb ftp/#deb ftp/#g' /etc/apt/sources.list
sudo sh -c "echo 'deb http://ftp.de.debian.org/debian sid main' sudo >> /etc/apt/sources.list"
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 648ACFD622F3D138

# везде
sudo apt update; sudo apt install ceph-mgr-diskprediction-local -y


# на сервере
sudo apt install ceph-mgr-dashboard python-routes -y


***




**************************


# Заходим на все Ноды и создаем пользователя ceph-adm:
sudo echo "$(whoami) ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$(whoami)
sudo chmod 0440 /etc/sudoers.d/$(whoami)
sudo pdpl-user -i 63 $(whoami)

sudo echo "$(whoami) ALL = (ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$(whoami)
sudo chmod 0440 /etc/sudoers.d/$(whoami)
sudo pdpl-user -i 63 $(whoami)



user_name ALL=(ALL) NOPASSWD:ALL

# монтируем образы в папку FTP
sudo mount /dev/sdb1 /srv/ftp/iso/
sudo mount /srv/ftp/iso/astra17.iso /srv/ftp/repo/astra17
sudo mount /srv/ftp/iso/astra17-devel-1.iso /srv/ftp/repo/astra17-devel-1
sudo mount /srv/ftp/iso/astra17-devel-2.iso /srv/ftp/repo/astra17-devel-2

# прописываем пути обновлений
sudo tee /etc/apt/sources.list<<EOF
deb ftp://adm/repo/astra17 1.7_x86-64 contrib main non-free
deb ftp://adm/repo/astra17-devel-1 1.7_x86-64 contrib main non-free
deb ftp://adm/repo/astra17-devel-2 1.7_x86-64 contrib main non-free
EOF

sudo tee /etc/hosts<<EOF
127.0.0.1      localhost

192.168.11.90  adm
192.168.11.91  node1
192.168.11.92  node2
192.168.11.93  node3
EOF

# Создаем ключ для ssh 
ssh-keygen -b 4096 -t rsa -f /home/$(whoami)/.ssh/id_rsa -N ""

# Создаем список хостов
tee remote-hosts<<EOF
node1
node2
node3
EOF


# Опрашиваем всех и собираем фингерпинг
ssh-keyscan -f ./remote-hosts >> ~/.ssh/known_hosts

# Ставим sshpass для передачи пароля текстом
sudo apt update; sudo apt install sshpass -y


for node_id in $(cat remote-hosts);
do
#sshpass -p 12345678 ssh-copy-id $node_id;
ssh $node_id 'sudo whoami';
done


# Настраиваем Ноды, раскидываем ssh-key, hosts, репозитории, обновления, ставим python
for node_id in $(cat remote-hosts);
do
ssh $node_id 'echo "user ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/user';
ssh $node_id 'sudo chmod 0440 /etc/sudoers.d/user';
ssh $node_id 'sudo pdpl-user -i 63 user';

scp /etc/hosts $node_id:/tmp/hosts;
scp /etc/apt/sources.list $node_id:/tmp/sources.list;
ssh $node_id 'sudo cp /tmp/hosts /etc/hosts';
ssh $node_id 'sudo cp /tmp/sources.list /etc/apt/sources.list';
ssh $node_id 'sudo apt update; sudo apt install ntp -y';
ssh $node_id 'sudo systemctl enable ntp; sudo systemctl start ntp';
done







# node1-3 adm
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/#g' /etc/ssh/sshd_config
systemctl restart ssh

ssh-keygen -b 4096 -t rsa -f /root/.ssh/id_rsa -N ""
passwd


# adm
KEY=$(sudo cat /root/.ssh/id_rsa.pub)
ssh root@node1 "bash -c \"echo $KEY >> /root/.ssh/authorized_keys\""
ssh root@node2 "bash -c \"echo $KEY >> /root/.ssh/authorized_keys\""
ssh root@node3 "bash -c \"echo $KEY >> /root/.ssh/authorized_keys\""

sh -c "echo 'nameserver 8.8.8.8' sudo >> /etc/resolv.conf"

# монтируем образы в папку FTP
mount /dev/sdb1 /srv/ftp/iso/
mount /srv/ftp/iso/astra17.iso /srv/ftp/repo/astra17
mount /srv/ftp/iso/astra17-devel-1.iso /srv/ftp/repo/astra17-devel-1
mount /srv/ftp/iso/astra17-devel-2.iso /srv/ftp/repo/astra17-devel-2

mcedit /etc/apt/sources.list
deb ftp://adm/repo/astra17 1.7_x86-64 contrib main non-free
deb ftp://adm/repo/astra17-devel-1 1.7_x86-64 contrib main non-free
deb ftp://adm/repo/astra17-devel-2 1.7_x86-64 contrib main non-free

#на сервер
apt install ansible git python-pip python3-apt ceph -y


#на нодах
apt install ceph python3-apt -y

sed -i 's/deb cdrom/#deb cdrom/#g' /etc/apt/sources.list

cd /usr/lib/python3/dist-packages


sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 648ACFD622F3D138



git clone https://github.com/vanitoo/acepht.git
sudo -i
cd /home/user/acepht/v4/

cp /etc/debian_version /etc/debian_version.old
cp /etc/issue /etc/issue.old
cp /etc/issue.net /etc/issue.net.old
cp /etc/locale.alias /etc/locale.alias.old
cp /etc/profile /etc/profile.old
cp /usr/lib/os-release /usr/lib/os-release.old

cp ./debian_version /etc/debian_version
cp ./issue /etc/issue
cp ./issue.net /etc/issue.net
cp ./locale.alias /etc/locale.alias
cp ./profile /etc/profile
cp ./os-release /usr/lib/os-release

apt install ca-certificates ansible git python-pip python3-apt python-apt ceph -y

tee -a remote-hosts<<EOF
node1
node2
node3
EOF

for node_id in $(cat remote-hosts); do
ssh $node_id 'sudo apt update;  sudo apt install ca-certificates ceph python3-apt python-apt -y';
done



sudo tee /etc/apt/sources.list<<EOF
deb ftp://adm/repo/astra17 1.7_x86-64 contrib main non-free
deb ftp://adm/repo/astra17-devel-1 1.7_x86-64 contrib main non-free
deb ftp://adm/repo/astra17-devel-2 1.7_x86-64 contrib main non-free
EOF

sudo tee -a /etc/hosts<<EOF
127.0.0.1      localhost

192.168.11.90  adm
192.168.11.91  node1
192.168.11.92  node2
192.168.11.93  node3
EOF


sudo systemctl enable ntp; sudo systemctl start ntp


cd /usr/lib/python3/dist-packages
sudo ln -s apt_inst.cpython-37m-x86_64-linux-gnu.so apt_inst.so
sudo ln -s apt_pkg.cpython-37m-x86_64-linux-gnu.so apt_pkg.so

sudo sh -c "echo 'deb https://mirror.yandex.ru/debian/ buster main contrib non-free' sudo >> /etc/apt/sources.list"
sudo sed -i 's/deb ftp/#deb ftp/#g' /etc/apt/sources.list

sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 04EE7237B7D453EC
sudo apt update; sudo apt install software-properties-common -y


git clone https://github.com/ceph/ceph-ansible
cd ceph-ansible
git checkout stable-4.0
pip install -r requirements.txt


sudo sh -c "echo 'deb http://ftp.de.debian.org/debian sid main' sudo >> /etc/apt/sources.list"
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 648ACFD622F3D138
sudo apt update; sudo apt install ceph-mgr-diskprediction-local -y

# на adm
sudo apt install ceph-mgr-dashboard python-routes -y


sudo tee ./inventory_hosts<<EOF
# Ceph admin user for SSH and Sudo
[all:vars]
ansible_ssh_user=ceph-adm
ansible_become=true
ansible_become_method=sudo
ansible_become_user=ceph-adm

# Ceph Monitor Nodes
[mons]
node1
node2
node3

# Manager Daemon Nodes
[mgrs]
node1
node2
node3

# set OSD (Object Storage Daemon) Node
[osds]
node1
node2
node3

# Grafana server
[grafana-server]
node1
node2
node3
EOF


sudo tee ./group_vars/all.yml<<EOF
---
grafana_server_group_name: grafana-server
ceph_origin: repository
ceph_repository: community
ceph_stable_release: octopus
generate_fsid: true
monitor_address_block: 192.168.11.0/24
journal_size: 5120
public_network: 192.168.11.0/24
cluster_network: 192.168.11.0/24
dashboard_enabled: True
dashboard_protocol: https
dashboard_port: 8443
dashboard_admin_user: admin
dashboard_admin_password: admin123
dashboard_crt: ''
dashboard_key: ''
grafana_admin_user: admin
grafana_admin_password: admin123
EOF


sudo tee ./group_vars/mons.yml<<EOF
---
dummy:
EOF

sudo tee ./group_vars/mons.yml<<EOF
---
dummy:
devices:
  - /dev/sdb
osd_auto_discovery: true
EOF

cp ./site.yml.sample ./site.yml
sudo sed -i 's/ - mdss/# - mdss/#g' ./site.yml
sudo sed -i 's/ - rgws/# - rgws/#g' ./site.yml
sudo sed -i 's/ - nfss/# - nfss/#g' ./site.yml
sudo sed -i 's/ - rbdmirrors/# - rbdmirrors/#g' ./site.yml
sudo sed -i 's/ - clients/# - clients/#g' ./site.yml
sudo sed -i 's/ - iscsigws/# - iscsigws/#g' ./site.yml
sudo sed -i 's/ - iscsi-gw/# - iscsi-gw/#g' ./site.yml
sudo sed -i 's/ - rgwloadbalancers/# - rgwloadbalancers/#g' ./site.yml

ansible-playbook ./site.yml -i ./inventory_hosts



# Создаем ключ для ssh 
ssh-keygen -b 4096 -t rsa -f /home/$(whoami)/.ssh/id_rsa -N ""

# Создаем список хостов
tee -a remote-hosts<<EOF
node1
node2
node3
EOF

# Опрашиваем всех и собираем фингерпинг
ssh-keyscan -f ./remote-hosts >> ~/.ssh/known_hosts

# Настраиваем Ноды, раскидываем ssh-key, hosts, репозитории, обновления, ставим python
for node_id in $(cat remote-hosts);
do
sshpass -p pa55w0rd ssh-copy-id $node_id -f;
done
