# astra linux 1.7 + ceph14 + ceph-deploy
#
# конф для 3 нод + 1 админский
# сеть везде настроена
# диск с дистрибами подключен к adm


# На всех нодах 
sudo -i
# Заходим на все Ноды и создаем пользователя ceph-adm:
sudo useradd  -m -c "ceph-adm" -s /bin/bash -p $(openssl passwd pa55w0rd) ceph-adm
echo "ceph-adm ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ceph-adm
sudo chmod 0440 /etc/sudoers.d/ceph-adm
sudo pdpl-user -i 63 ceph-adm



# Заходим на машину adm
sudo -i

sudo useradd  -m -c "ceph-adm" -s /bin/bash -p $(openssl passwd pa55w0rd) ceph-adm
echo "ceph-adm ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ceph-adm
sudo chmod 0440 /etc/sudoers.d/ceph-adm
sudo pdpl-user -i 63 ceph-adm

sh -c "echo 'nameserver 8.8.8.8' sudo >> /etc/resolv.conf"

# монтируем образы в папку FTP
mount /dev/sdb1 /srv/ftp/iso/
mount /srv/ftp/iso/astra17.iso /srv/ftp/repo/astra17
mount /srv/ftp/iso/astra17-devel-1.iso /srv/ftp/repo/astra17-devel-1
mount /srv/ftp/iso/astra17-devel-2.iso /srv/ftp/repo/astra17-devel-2

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

sudo apt update; sudo apt install chrony -y;

sudo mkdir /etc/chrony

sudo tee -a /etc/chrony/chrony.conf<<EOF
allow 192.168.11.0/24
local stratum 10
EOF

sudo tee /etc/chrony/chrony.conf.client<<EOF
server adm iburst

stratumweight 0
driftfile /var/lib/chrony/chrony.drift
rtcsync
makestep 10 3
bindcmdaddress 127.0.0.1
keyfile /etc/chrony/chrony.keys
commandkey 1
generatecommandkey
noclientlog
logchange 0.5
logdir /var/log/chrony
EOF

sudo systemctl enable chronyd
sudo systemctl start chronyd
sudo systemctl restart chronyd



# Входим под ним
su - ceph-adm

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

# Ставим sshpass для передачи пароля текстом
sudo apt update; sudo apt install sshpass -y


for node_id in $(cat remote-hosts);
do
sshpass -p pa55w0rd ssh-copy-id $node_id;
done


# Настраиваем Ноды, раскидываем ssh-key, hosts, репозитории, обновления, ставим python
for node_id in $(cat remote-hosts);
do
scp /etc/hosts $node_id:/tmp/hosts;
scp /etc/apt/sources.list $node_id:/tmp/sources.list;
scp /etc/chrony/chrony.conf.client $node_id:/tmp/chrony.conf.client

ssh $node_id 'sudo cp /tmp/hosts /etc/hosts';
ssh $node_id 'sudo cp /tmp/sources.list /etc/apt/sources.list';

ssh $node_id 'sudo apt update; sudo apt install python chrony -y';
ssh $node_id 'sudo cp /tmp/chrony.conf.client /etc/chrony/chrony.conf';
ssh $node_id 'sudo systemctl enable chronyd; sudo systemctl start chronyd';

ssh $node_id 'sudo apt autoremove -y';
ssh $node_id 'sudo systemctl restart chronyd';

done



sudo apt install ceph-deploy -y

mkdir mycluster
cd mycluster

# Создаем новый кластер:
ceph-deploy new node{1..3}

tee -a ceph.conf<<EOF
monitor_interface: eth0
public_network: 192.168.11.0/24
cluster_network: 192.168.11.0/24
journal_size: 5120
EOF

# Устанавливаем дистрибутив Ceph на машины:
ceph-deploy install node1 node2 node3 
#ceph-deploy install --mon node1 node2 node3 
#ceph-deploy install --osd node1 node2 node3 
#ceph-deploy install --mgr node1 node2 node3 


# Создаем мониторы, указанные при создании кластера:
ceph-deploy mon create-initial
ceph-deploy mgr create node1 node2 node3



# перезагружаем ноды, для применения настроек
#for ceph_id in $(cat ../remote-hosts); do ssh ceph-adm@$ceph_id sudo reboot; done
# логинемся к adm
#su - ceph-adm
#cd mycluster



#установить основные компоненты Ceph на административную рабочую станцию
##ceph-deploy install --cli node1 node2 node3
# копировать конфигурационный файл
ceph-deploy admin node1 node2 node3

ceph-deploy config push node1 node2 node3


# Превращаем диски в OSD и создаем соответствующие демоны:
ceph-deploy osd create --data /dev/sdb node1
ceph-deploy osd create --data /dev/sdb node2
ceph-deploy osd create --data /dev/sdb node3



# установка даш борда, ставим дашборд на все ноды с MGR
for node_id in $(cat remote-hosts);
do
  ssh ceph-adm@$node_id 'sudo apt install ceph-mgr-dashboard -y';
done


# логинимся на node1
sudo ceph mgr module enable dashboard
sudo ceph mgr module ls | grep dashboard
sudo ceph dashboard create-self-signed-cert
sudo ceph dashboard ac-user-create admin admin administrator
sudo ceph mgr services


for node_id in $(cat remote-hosts);
#for node_id in node1;
do
ssh $node_id 'sudo ceph mgr module enable dashboard'
ssh $node_id 'sudo ceph dashboard create-self-signed-cert'
ssh $node_id 'sudo ceph dashboard ac-user-create admin admin123 administrator'
ssh $node_id 'sudo ceph mgr services'
done





# The END