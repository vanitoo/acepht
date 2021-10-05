deb http://mirror.yandex.ru/debian stretch main


# astra linux 1.7 + ceph14 + ansible
# версия Андрей
#
# конф для 3 нод + 1 админский
# сеть везде настроена
# диск с дистрибами подключен к adm

sudo -i

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

