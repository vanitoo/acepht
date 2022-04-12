sudo tee /etc/hosts<<EOF
127.0.0.1      localhost

192.168.11.90  srv17
192.168.11.91  node117
192.168.11.92  node217
192.168.11.93  node317
EOF


sudo tee /etc/apt/sources.list<<EOF
deb ftp://srv17/repo/astra17 1.7_x86-64 contrib main non-free
deb ftp://srv17/repo/astra17-devel-1 1.7_x86-64 contrib main non-free
deb ftp://srv17/repo/astra17-devel-2 1.7_x86-64 contrib main non-free
EOF


sudo apt update; sudo apt install git -y
git clone https://github.com/vanitoo/acepht.git