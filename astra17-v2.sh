# сеть настроена
# диск с дистриба подключен

sudo -i

sh -c "echo 'nameserver 8.8.8.8' sudo >> /etc/resolv.conf"

mount /dev/sdb1 /srv/ftp/iso/
mount /srv/ftp/iso/astra17.iso /srv/ftp/repo/astra17
mount /srv/ftp/iso/astra17-devel-1.iso /srv/ftp/repo/astra17-devel-1
mount /srv/ftp/iso/astra17-devel-2.iso /srv/ftp/repo/astra17-devel-2

sudo tee -a /etc/apt/sources.list<<EOF
deb ftp://adm/repo/astra17 1.7_x86-64 contrib main non-free
deb ftp://adm/repo/astra17-devel-1 1.7_x86-64 contrib main non-free
deb ftp://adm/repo/astra17-devel-2 1.7_x86-64 contrib main non-free
EOF

# Создаем пользователя ceph-adm:
sudo useradd  -m -c "ceph-adm" -s /bin/bash -p $(openssl passwd pa55w0rd) ceph-adm
echo "ceph-adm ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ceph-adm
sudo chmod 0440 /etc/sudoers.d/ceph-adm
sudo pdpl-user -i 63 ceph-adm

# Входим под ним
su - ceph-adm

# Создаем ключ для ssh 
ssh-keygen -b 4096 -t rsa -f /home/$(whoami)/.ssh/id_rsa -N ""

# Создаем список хостов
sudo tee -a remote-hosts<<EOF
node1
node2
node3
EOF

# Опрашиваем всех и собираем фингерпинг
ssh-keyscan -f ./remote-hosts >> ~/.ssh/known_hosts

# Ставим sshpass для передачи пароля текстом
sudo apt update; sudo apt install sshpass -y


# Настраиваем Ноды, раскидываем ssh-key, hosts, репозитории, обновления, ставим python
for node_id in $(seq 1 3);
do
sshpass -p pa55w0rd ssh-copy-id ceph-adm@node$node_id;
scp /etc/hosts ceph-adm@node$node_id:/tmp/hosts;
ssh ceph-adm@node$node_id 'sudo cp /tmp/hosts /etc/hosts';
scp /etc/apt/sources.list ceph-adm@node$node_id:/tmp/sources.list;
ssh ceph-adm@node$node_id 'sudo cp /tmp/sources.list /etc/apt/sources.list';
ssh ceph-adm@node$node_id 'sudo apt update; sudo apt install python ntp -y';
ssh ceph-adm@node$node_id 'sudo systemctl enable ntp; sudo systemctl start ntp';
done

sudo apt install ceph-deploy

# Создаем новый кластер:
ceph-deploy new node1 node2 node3

# Устанавливаем дистрибутив Ceph на машины:
ceph-deploy install --mon node1 node2 node3 
ceph-deploy install --osd node1 node2 node3 
ceph-deploy install --mgr node1 node2 node3 


# Создаем мониторы, указанные при создании кластера:
ceph-deploy mon create-initial
ceph-deploy mgr create node1 node2 node3

# перезагружаем ноды, для применения настроек
for ceph_id in $(seq 3 -1 1); do ssh ceph-adm@node$ceph_id sudo reboot; done


#установить основные компоненты Ceph на административную рабочую станцию
ceph-deploy install --cli node1
# копировать конфигурационный файл
ceph-deploy admin node1

ceph-deploy config push node1 node2 node3


# Превращаем диски в OSD и создаем соответствующие демоны:
ceph-deploy osd create --data /dev/sdb node1
ceph-deploy osd create --data /dev/sdb node2
ceph-deploy osd create --data /dev/sdb node3



# установка даш борда, ставим дашборд на все ноды с MGR
for node_id in $(seq 1 3); do ssh ceph-adm@node$node_id 'sudo apt install ceph-mgr-dashboard -y'; done

sudo ceph mgr module enable dashboard
sudo ceph mgr module ls | grep dashboard
sudo ceph dashboard create-self-signed-cert
sudo ceph dashboard ac-user-create admin admin administrator
sudo ceph mgr services



