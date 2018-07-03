#!/bin/bash
#
# WORK IN PROGRESS; NOT GUARANTEED TO WORK
#
# An automated script to assist with installing Vertcoin full node(s)
# -------------------------------------------------------------------
# AUTHORS:
# jochemin   | Twitter: @jochemin | BTC Donations --> 3FM6FypcrSVhdHh7cpVQMrhPXPZ6zcXeYU
# Sam Sepiol | Email: ecorp-sam.sepiol@protonmail.com 
# SPECIAL THANKS:
# Thanks @b17z, this fork would not have happened without you. Thanks
# for your help and inspiration. 
# -------------------------------------------------------------------
# Functions:
#           color functions
#               greentext
#               yellowtext
#               redtext
#           hd_detect           | detect USB flash drive, format
#           hd_config           | configure USB flash drive
#           swap_config         | configure swap file to reside on formatted USB flash drive
#           user_input          | take user input for rpcuser and rpcpass
#           network_addr        | grab the LAN network addresses of the host running this script
#           secure              | modify iptables to limit connections for security purposes
#           update_rasp         | update the system
#           install_berkeley    | install berkeley database 4.8 for wallet functionality
#           install_vertcoind   | clone, build and install vertcoin core daemon
#           config_vertcoin     | create ~/.vertcoin/vertcoin.conf to configure vertcoind
#           install_depends     | install the required dependencies to run this script
# -------------------------------------------------------------------

# fail on error; debug all lines
set -eu -o pipefail


# colors for console output
TEXT_RESET='\e[0m'
TEXT_YELLOW='\e[0;33m'
TEXT_RED='\e[1;31m'
TEXT_GREEN='\e[0;32m'


# script variables
user=$(logname)
userhome='/home/'$user
FOLD1='/dev/'
PUBLICIP="$(curl -s ipinfo.io/ip)"

# -----------------------------------

# color functions
function greentext(){
    echo -e -n "\e[0;32m$1"
    echo -e -n '\033[0m\n'
}
function yellowtext(){
    echo -e -n "\e[0;33m$1"
    echo -e -n '\033[0m\n'
}
function redtext(){
    echo -e -n "\e[1;31m$1"
    echo -e -n '\033[0m\n'
}


# hd_detect | USB flash drive detect; prompt for formatting
function hd_detect {
    find_drive="$(lsblk -dlnb | awk '$4<=16008609792' | numfmt --to=iec --field=4 | cut -c1-3)"
    drive=$FOLD1$find_drive
    drive_size="$(df -h "$drive" | sed 1d |  awk '{print $2}')"
    while true; do
        echo -e "$TEXT_RED"
        read -p "$drive_size $drive will be formatted. Do you wish to continue? (y/n) " yn
        case $yn in
            [Yy]* ) DRIVE_CONF=true; break;;
            [Nn]* ) echo "This script needs to format the entire flash drive.";
                    echo -e "$TEXT_RESET"; exit;;
            * ) echo "Do you wish to continue? (y/n)";;
        esac
        echo -e "$TEXT_RESET"
    done
}

# hd_config | configure USB flash drive
function hd_config {
    drive=$drive"1"
        if mount | grep "$drive" > /dev/null; then
            umount -l "$drive" > /dev/null
        fi
    yellowtext 'Formatting USB flash drive...'
    # format usb disk as ext4 filesystem    
    sudo mkfs.ext4 -F "$drive" -L storage
    greentext 'Successfully formatted flash drive!'
    # locally declare UUID as the value given by blkid
    UUID="$(blkid -o value -s UUID "$drive")"
    yellowtext 'Creating Vertcoin data folder...'
    VTCDIR='/home/'$user'/.vertcoin'
    mkdir -p "$VTCDIR"
    yellowtext 'Modifying fstab configuration...'
    sudo sed -i".bak" "/$UUID/d" /etc/fstab
    echo "UUID=$UUID  $VTCDIR  ext4  defaults,noatime  0    0" >> /etc/fstab
        if mount | grep "$drive" > /dev/null; then
            :
        else
            sudo mount -a
        fi
    sudo chmod 777 "$VTCDIR"
    greentext 'Successfully configured USB flash drive!'
}

# swap_config | configure swap file to reside on formatted flash drive
function swap_config {
    yellowtext 'Configuring swap file to reside on USB flash drive...'
    sudo -u "$user" mkdir -p /home/"$user"/.vertcoin/swap
    dd if=/dev/zero of=/home/"$user"/.vertcoin/swap/swap.file bs=1M count=2148
    chmod 600 /home/"$user"/.vertcoin/swap/swap.file
    sudo sed -i".bak" "/CONF_SWAPFILE/d" /etc/dphys-swapfile
    sudo sed -i".bak" "/CONF_SWAPSIZE/d" /etc/dphys-swapfile
    echo "CONF_SWAPFILE=/home/$user/.vertcoin/swap/swap.file" >> /etc/dphys-swapfile
    # set aside 2GB of memory for swap    
    echo "CONF_SWAPSIZE=2048" >> /etc/dphys-swapfile
    mkswap /home/"$user"/.vertcoin/swap/swap.file
    swapon /home/"$user"/.vertcoin/swap/swap.file
    echo "/home/$user/.vertcoin/swap/swap.file  none  swap  defaults  0    0" >> /etc/fstab
    greentext 'Successfully configured swap space!'
}

# user_input | take user input for rpcuser and rpcpass
function user_input {
    # check for USB flash drive
    while true; do
        echo -e "$TEXT_YELLOW"
        read -p "Is the USB flash drive connected? It will be formatted. (y/n)" yn
        case $yn in
            [Yy]* ) hd_detect; break;;  # if we have hd_config value we can configure it
            [Nn]* ) echo "Please connect USB flash drive and retry."; exit;;
            * ) echo "Do you wish to continue? (y/n)";;
        esac
    done
    echo 'Vertcoin requires both an rpcuser & rpcpassword, please enter your preferred values: '
    read -p 'Enter username: ' rpcuser
    read -s -p 'Enter password: ' rpcpass
    echo
}

# network_addr | grab the LAN network addresses of the host running this script
function network_addr {
    network_address=$(ip -o -f inet addr show | awk '/scope global/{sub(/[^.]+\//,"0/",$4);print $4}')
}

# secure | modify iptables to limit connections for security purposes
function secure {
    # call the function network_addr    
    network_addr
    # configure iptables    
    yellowtext 'Configuring iptables...'
    # allow traffic from LAN    
    iptables -A INPUT -s "$network_address" -j ACCEPT
    greentext 'All traffic from LAN allowed...'
    # limit total incoming connections = 250    
    iptables -A INPUT -p tcp --syn -m connlimit --connlimit-above 250 --connlimit-mask 0 -j DROP
    greentext 'Limited total incoming connections to 250...'
    # limit SSH connections to port 22 = 2
    iptables -A INPUT -p tcp --syn --dport 22 -m connlimit --connlimit-above 2 --connlimit-mask 0 -j DROP
    greentext 'Limited SSH connections to port 22 @ maximum of 2'
    # limit total connections to port 5889 (Vertcoin Mainnet) to 120
    iptables -A INPUT -p tcp --syn --dport 5889 -m connlimit --connlimit-above 120 --connlimit-mask 0 -j DROP
    greentext 'Limited total connections to port 5889 (Vertcoin Mainnet) to 120'
    # limit unique IP addresses to 6 connections
    iptables -I INPUT -p tcp --syn --dport 5889 -m connlimit --connlimit-above 6 -j REJECT
    greentext 'Limited unique IP addresses 6 connections to port 5889'
    # save the iptables rules; load the saved rules
    iptables-save > /etc/iptables.conf
    sed -i".bak" '/exit/d' /etc/rc.local
    echo 'iptables-restore < /etc/iptables.conf' >> /etc/rc.local
    echo 'exit 0' >> /etc/rc.local
    greentext 'Rules saved!'
}

# update_rasp | update the system
function update_rasp {
    yellowtext 'Initializing system update...'
    sudo apt-get update
    sudo apt-get upgrade -y
    sudo apt-get autoremove -y
    greentext 'Successfully updated system!'
    # check if reboot is needed
        if [ -f /var/run/reboot-required ]; then
            redtext 'Reboot required!'
        fi
}

# install_berkeley | install berkeley database 4.8 for wallet functionality
function install_berkeley {
    yellowtext 'Installing Berkeley (4.8) database...'
    sudo -u "$user" mkdir -p "$userhome"/bin
    cd "$userhome"/bin
    sudo -u "$user" wget http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz
    sudo -u "$user" tar -xzvf db-4.8.30.NC.tar.gz
    cd db-4.8.30.NC/build_unix/
    ../dist/configure --enable-cxx
    make
    sudo make install
    greentext 'Successfully installed Berkeley (4.8) database!'
}

# install_vertcoind | clone, build and install vertcoin core daemon
function install_vertcoind {
    yellowtext 'Installing Vertcoin Core...'
    rm -fR "$userhome"/bin/vertcoin
    cd "$userhome"/bin
    git clone https://github.com/vertcoin-project/vertcoin-core.git
    cd vertcoin-core/
    ./autogen.sh
    ./configure CPPFLAGS="-I/usr/local/BerkeleyDB.4.8/include -O2" LDFLAGS="-L/usr/local/BerkeleyDB.4.8/lib" --enable-upnp-default
    make
    sudo make install
    greentext 'Successfully installed Vertcoin Core!'
}

# config_vertcoin | create ~/.vertcoin/vertcoin.conf to configure vertcoind
function config_vertcoin {
    echo "server=1" >> /home/"$user"/.vertcoin/vertcoin.conf
    echo "rpcuser=$rpcuser" >> /home/"$user"/.vertcoin/vertcoin.conf
    echo "rpcpassword=$rpcpass" >> /home/"$user"/.vertcoin/vertcoin.conf
    echo 'dbcache=100' >> /home/"$user"/.vertcoin/vertcoin.conf
    echo 'maxmempool=100' >> /home/"$user"/.vertcoin/vertcoin.conf
    echo 'maxorphantx=10' >> /home/"$user"/.vertcoin/vertcoin.conf
    echo 'maxmempool=50' >> /home/"$user"/.vertcoin/vertcoin.conf
    echo 'maxconnections=40' >> /home/"$user"/.vertcoin/vertcoin.conf
    echo 'maxuploadtarget=5000' >> /home/"$user"/.vertcoin/vertcoin.conf
    echo 'usehd=1' >> /home/"$user"/.vertcoin/vertcoin.conf
    echo 'txindex=1' >> /home/"$user"/.vertcoin/vertcoin.conf
}

# install_depends | install the required dependencies to run this script
function install_depends {
    yellowtext 'Installing package dependencies...'
    sudo apt-get install -y build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils python3 libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev git fail2ban
    greentext 'Successfully installed required dependencies!'
}

# -------------BEGIN-MAIN-------------------

# check for sudo when running the script
if [ "$(id -u)" -ne 0 ]; then
    redtext "Please run this script with sudo!" >&2
    exit 1
fi

# clear the screen
clear

# check parameters
while test $# -gt 0
do
    key="$1"
    if [ "$key" = "secure" ]; then
        secure; exit 1
    else
        redtext 'Unknown parameter'; exit 1
    fi
done

# call user_input function | take user input for rpcuser and rpcpass
user_input
greentext 'Initializing the Vertcoin full node installation, please be patient...'
greentext '______________________________________________________________________'
# call update_rasp function | update the system
update_rasp
# call install_depends function | install the required dependencies to run this script
install_depends
# call secure function | modify iptables to limit connections for security purposes
secure

# configure USB flash drive ; call hd_config function, then call swap_config function
if [ "$DRIVE_CONF" = "true" ]; then
    hd_config
    swap_config
fi

# call install_berkeley function | install berkeley database 4.8 for wallet functionality
install_berkeley

# call install_vertcoind | clone, build and install vertcoin core daemon
install_vertcoind

# call config_vertcoin | create ~/.vertcoin/vertcoin.conf to configure vertcoind
config_vertcoin

echo 'Script was successful! Transfer blockchain to this host and start Vertcoin'
