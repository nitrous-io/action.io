#!/bin/bash
set -e -x
exec > >(tee /var/log/user-data.log|logger -t action-boxer -s 2>/dev/console) 2>&1
export DEBIAN_FRONTEND=noninteractive
apt-get -qq update
apt-get -qq install lxc debootstrap bridge-utils build-essential gdebi-core
sed -i "s/#RUN=yes/RUN=yes/g" /etc/default/lxc
/etc/init.d/lxc start
NETWORK_DEFN=$(cat<<EOF
\n# This file describes the network interfaces available on your system
\n# and how to activate them. For more information, see interfaces(5).
\n
\n# The loopback network interface
\nauto lo
\niface lo inet loopback
\n
\n# The primary network interface
\nauto eth0
\niface eth0 inet dhcp
\n\tpre-up iptables-restore < /etc/iptables.rules
\n\tpost-down iptables-save > /etc/iptables.rules
\n
\n# Bridget network interface for all LXC containers
\nauto br-lxc
\niface br-lxc inet static
\n\taddress 192.168.254.1
\n\tnetmask 255.255.255.0
\n
\n\tpost-up echo 1 > /proc/sys/net/ipv4/ip_forward
\n\tpost-up iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
\n\tpre-down echo 0 > /proc/sys/net/ipv4/ip_forward
\n\tpre-down iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
\n
\n\tbridge_ports none
\n\tbridge_stp off
\n
EOF
)
touch /etc/iptables.rules
echo -e $NETWORK_DEFN > /etc/network/interfaces
ifup br-lxc

# init.d script for tty.js
INIT_D_TTY=$(cat<<EOF
#!/bin/sh
\n#
\n# Simple tty.js init.d script conceived to work on Linux systems
\n# as it does use of the /proc filesystem.
\n
\nEXECNAME=tty.js
\nEXEC=/etc/actionio/tty.js/bin/\${EXECNAME}
\nCONFIG=/etc/actionio/config.json
\nBOX_OWNER=\$(cat /etc/actionio/box_owner)
\n
\ncase "\$1" in
\n\tstart)
\n\t\tPID=\$(pidof \$EXECNAME)
\n\t\tif [ \$PID ]
\n\t\tthen
\n\t\t\t\techo "tty.js exists with pid \$PID, process is already running or crashed"
\n\t\telse
\n\t\t\t\techo "Starting tty.js server..."
\n\t\t\t\tsudo -u \$BOX_OWNER -i \$EXEC --config \$CONFIG --daemonize
\n\t\tfi
\n\t\t;;
\n\tstop)
\n\t\tPID=\$(pidof \$EXECNAME)
\n\t\tif [ -z \$PID ]
\n\t\tthen
\n\t\t\t\techo "tty.js process is not running"
\n\t\telse
\n\t\t\t\techo "Stopping ..."
\n\t\t\t\tkill -9 \$PID
\n\t\t\t\twhile [ \$(pidof \$EXECNAME) ]
\n\t\t\t\tdo
\n\t\t\t\t\t\t\t\techo "Waiting for tty.js to shutdown ..."
\n\t\t\t\t\t\t\t\tsleep 1
\n\t\t\t\tdone
\n\t\t\t\techo "tty.js stopped"
\n\t\tfi
\n\t\t;;
\n\t\t*)
\n\t\t\t\techo "Please use start or stop as first argument"
\n\t\t\t\t;;
\nesac


EOF
)

TTY_JS_CONFIG=$(cat<<EOF

EOF
)

# Install Redis
mkdir -p /root/installs
cd /root/installs
wget http://assets.action.io/debs/20120518/redis-server_2.4.13_fpm0_amd64.deb
gdebi --n redis-server_2.4.13_fpm0_amd64.deb
sed -i "s/daemonize no/daemonize yes/g" /etc/redis/redis.conf
sed -i "s/appendonly no/appendonly yes/g" /etc/redis/redis.conf
sed -i "s/# appendfilename appendonly.aof/appendfilename \/var\/lib\/redis\/appendonly.aof/g" /etc/redis/redis.conf
sed -i "s/dir .\//dir \/var\/redis\//g" /etc/redis/redis.conf
sed -i "s/logfile stdout/logfile \/var\/log\/redis.log/g" /etc/redis/redis.conf

useradd -m -s /bin/bash redis
update-rc.d redis-server defaults
/etc/init.d/redis-server start

POPULATE_IPS_SH=$(cat<<EOF
#!/bin/bash
\n
\nlistlength="`redis-cli llen available_ips`"
\nif [ "\$listlength" -eq "0" ]
\n  then
\n    for i in {2..254}
\n    do
\n      command="redis-cli rpush available_ips \$i"
\n      echo "Executing \$command"
\n      \$command
\n    done
\n    echo "Inserted 2..254 in redis list"
\nfi
EOF
)
echo -e $POPULATE_IPS_SH > /root/populate-ips.sh
chmod +x /root/populate-ips.sh
/root/populate-ips.sh

POPULATE_PORTS_SH=$(cat<<EOF
#!/bin/bash
\n
\nlistlength="`redis-cli llen available_ports`"
\nif [ "\$listlength" -eq "0" ]
\n  then
\n    for i in {10000..10250}
\n    do
\n      command="redis-cli rpush available_ports \$i"
\n      echo "Executing \$command"
\n      \$command
\n    done
\n    echo "Inserted Available Ports"
\nfi
EOF
)
echo -e $POPULATE_PORTS_SH > /root/populate-ports.sh
chmod +x /root/populate-ports.sh
/root/populate-ports.sh


# Install Template Containers for Rails + NodeJS

LXC_CONF=$(cat<<EOF
lxc.network.type = veth
\nlxc.network.flags = up
\nlxc.network.link = br-lxc
\nlxc.cgroup.cpu.shares = 512
\nlxc.cgroup.memory.limit_in_bytes = 256M
\nlxc.cgroup.memory.memsw.limit_in_bytes = 256M
EOF
)
mkdir -p /root/lxc
echo -e $LXC_CONF > /root/lxc/default.conf
debootstrap --arch amd64 precise /var/cache/lxc/precise/rootfs-amd64 http://archive.ubuntu.com/ubuntu
lxc-create -n rails-container-template -t ubuntu -f /root/lxc/default.conf -- -r precise
# Install sources.list in both the containers
cp /etc/apt/sources.list /var/lib/lxc/rails-container-template/rootfs/etc/apt/sources.list

# Install Ruby/Rails in the rails-container-template

RAILS_TEMPLATE_ROOT=/var/lib/lxc/rails-container-template/rootfs

touch $RAILS_TEMPLATE_ROOT/root/script.bash
chmod +x $RAILS_TEMPLATE_ROOT/root/script.bash
echo -e $INIT_D_TTY > $RAILS_TEMPLATE_ROOT/etc/init.d/tty.js
cat > $RAILS_TEMPLATE_ROOT/root/script.bash << "EOF"

#!/bin/bash
cd ~/
apt-get -yq update
locale-gen en_US
locale-gen en_US.UTF-8
dpkg-reconfigure locales
apt-get install -yqq gdebi-core wget build-essential libsqlite3-dev postgresql libpq-dev ssh git-core emacs23-nox vim-nox tmux screen man
wget http://assets.action.io/debs/20120518/ruby_1.9.3.125_fpm1_amd64.deb
gdebi --n ruby_1.9.3.125_fpm1_amd64.deb
# Install Node too (for CoffeeScript/Less, etc.)
wget http://assets.action.io/debs/20120518/nodejs_0.6.17_fpm0_amd64.deb
gdebi --n nodejs_0.6.17_fpm0_amd64.deb
# Install tty.js for browser-based SSH
mkdir -p /etc/actionio
echo -e '{\n\t"users": {},\n\t"https": {\n\t\t"key": null,\n\t\t"cert": null\n\t},\n\t"port": 60001,\n\t"term": { "termName": "xterm-256color" }\n}' > /etc/actionio/config.json
chmod 644 /etc/actionio/config.json
cd /etc/actionio
if [ -f tty.js.tar.gz ]
  then
    rm -rf tty.js*
fi

wget --no-cache http://assets.action.io/packages/tty.js-256c39408694a7c706f8bbfb7638e02e00c83542.tar.gz -O tty.js.tar.gz
if [ -f tty.js.tar.gz ]
  then
    tar -zxvf tty.js.tar.gz
    cd tty.js
    npm install
fi

# Install init.d script for tty.js
chmod +x /etc/init.d/tty.js
update-rc.d tty.js defaults
# Install new Authorized Keys File in OpenSSH
sed -i "s/^AuthorizedKeysFile.*$/AuthorizedKeysFile %h\/.ssh\/authorized_keys \/etc\/ssh\/univ_public_keys/" /etc/ssh/sshd_config
touch /etc/ssh/univ_public_keys
chown root:root /etc/ssh/univ_public_keys
chmod 0644 /etc/ssh/univ_public_keys

gem install rails

EOF

chroot /var/lib/lxc/rails-container-template/rootfs /bin/bash /root/script.bash