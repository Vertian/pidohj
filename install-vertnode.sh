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
#           grab_vtc_release    | grab the latest vertcoind release from github
#           wait_for_continue   | function for classic "Press spacebar to continue..." 
#           grab_vtc_release    | grab the latest vertcoind release from github
#           grab_bootstrap      | grab the latest bootstrap.dat from alwayshashing
#           compile_or_compiled | prompt the user for input; would you like to build vertcoin core 
#           load_blockchain     | prompt the user for input; would you like to sideload the chain or 
#                               | grab the latest bootstrap.dat
#           install_p2pool      | function to download and configure p2pool
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
# ~ $ ifconfig eth0 | grep "inet "
#       inet 192.168.1.6  netmask 255.255.255.0  broadcast 192.168.1.255
LANIP="$(ifconfig eth0 | grep "inet " | awk -F'[: ]+' '{ print $3 }')" # grab only the inet addr

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
    # list block devices that are less than or equal to 16GB, cut the first three characters
    # of lsblk -dlnb and pass to df -h
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
            * ) echo "Do you wish to continue? (y/n) ";;
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
    echo
    yellowtext 'Creating Vertcoin data folder...'
    VTCDIR='/home/'$user'/.vertcoin'
    mkdir -p "$VTCDIR"
    yellowtext 'Modifying fstab configuration...'
    echo    
    sudo sed -i".bak" "/$UUID/d" /etc/fstab
    echo "UUID=$UUID  $VTCDIR  ext4  defaults,noatime  0    0" >> /etc/fstab
        if mount | grep "$drive" > /dev/null; then
            :
        else
            sudo mount -a
        fi
    sudo chmod 777 "$VTCDIR"
    greentext 'Successfully configured USB flash drive!'
    echo
}

# swap_config | configure swap file to reside on formatted flash drive
function swap_config {
    # !! notify user the ability to begin sideloading blockchain
    echo "************************************"
    echo " NOTE: Sideloading the blockchain"
    echo " is now available. Please use an"
    echo " SFTP client such as WinSCP or"
    echo " FileZilla to connect to your"
    echo " Vertcoin node and copy the blocks"
    echo " and chainstate folder to the"
    echo " /home/$user/.vertcoin/ folder."
    echo "--------------------------------"
    echo " Username: $user "
    echo " Port: 22 "
    echo "************************************"
    # continue and configure swap    
    yellowtext 'Configuring swap file to reside on USB flash drive...'
    sudo -u "$user" mkdir -p /home/"$user"/.vertcoin/swap
    # dd will take a few minutes to complete
    echo 
    echo "This may take awhile, please be patient."
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
    echo    
    greentext 'Successfully configured swap space!'
    echo
}

# user_input | take user input for rpcuser and rpcpass
function user_input {
    # check for USB flash drive
    while true; do
        clear
        echo -e "$TEXT_YELLOW"
        read -p "Is the USB flash drive connected? It will be formatted. (y/n) " yn
        case $yn in
            [Yy]* ) hd_detect; break;;  # if we have hd_config value we can configure it
            [Nn]* ) echo "Please connect USB flash drive and retry."; exit;;
            * ) echo "Do you wish to continue? (y/n) ";;
        esac
    done
    clear
    echo 'Vertcoin requires both an rpcuser & rpcpassword, enter your preferred values: '
    read -p 'Enter username: ' rpcuser
    read -s -p 'Enter password: ' rpcpass
    echo
}

# network_addr | grab the LAN network address range of the host running this script
function network_addr {
    network_address=$(ip -o -f inet addr show | awk '/scope global/{sub(/[^.]+\//,"0/",$4);print $4}')
}

# wait_for_continue | function for classic "Press spacebar to continue..." 
function wait_for_continue {
    echo    
    echo "STFP: "$user $LANIP':22'
    echo
    read -n 1 -s -r -p "Press any key to continue when finished transferring blockchain..."
    echo
}

# secure | modify iptables to limit connections for security purposes
function secure {
    yellowtext 'Configuring firewall...'
    # install the dependancy 
    sudo apt-get install ufw -y
    # call the function network_addr    
    network_addr
    # configure ufw firewall   
    echo
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow from $network_address to any port 22 comment 'allow SSH from local LAN'
    ufw allow 5889 comment 'allow vertcoin core'
    ufw --force enable
    systemctl enable ufw
    ufw status
    echo 
    greentext 'Successfully configured firewall!'
    echo 
}

# update_rasp | update the system
function update_rasp {
    yellowtext 'Initializing system update...'
    sudo apt-get update
    sudo apt-get upgrade -y
    sudo apt-get autoremove -y
    greentext 'Successfully updated system!'
    echo
    # check if reboot is needed
        if [ -f /var/run/reboot-required ]; then
            redtext 'Reboot required!'
        fi
}

# install_depends | install the required dependencies to run this script
function install_depends {
    yellowtext 'Installing package dependencies...'
    sudo apt-get install -y build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils python3 libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev git fail2ban 
    greentext 'Successfully installed required dependencies!'
    echo
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
    echo
}

# install_vertcoind | clone, build and install vertcoin core daemon
function install_vertcoind {
    # call install_berkeley function to enable wallet functionality
    install_berkeley    
    # continue on compiling vertcoin from source
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
    echo
}

# grab_vtc_release | grab the latest vertcoind release from github
function grab_vtc_release {
    # grab the latest version number; store in variable $VERSION
    export VERSION=$(curl -s "https://github.com/vertcoin-project/vertcoin-core/releases/latest" | grep -o 'tag/[v.0-9]*' | awk -F/ '{print $2}')
    # grab the latest version release; deviation in release naming scheme will break this
    # release naming scheme needs to be: 'vertcoind-v(release#)-linux-armhf.zip' to work
    wget https://github.com/vertcoin-project/vertcoin-core/releases/download/$VERSION/vertcoind-v$VERSION-linux-armhf.zip
    unzip vertcoind-v$VERSION-linux-armhf.zip
    # clean up    
    rm vertcoind-v$VERSION-linux-armhf.zip
    # move vertcoin binaries to /usr/bin/ 
    mv vertcoind vertcoin-tx vertcoin-cli /usr/bin/
}

# grab_bootstrap | grab the latest bootstrap.dat from alwayshashing
function grab_bootstrap {
    yellowtext 'Downloading latest bootstrap.dat...'
    echo
    # download boostrap.dat
    wget http://alwayshashing.com/downloads/bootstrap.dat -P /home/"$user"/.vertcoin/
    echo
    greentext 'Successfully downloaded bootstrap.dat!'
    echo
}

# compile_or_compiled | prompt the user for input; would you like to build vertcoin core 
#                     | from source or would you like to grab the latest release binary?
function compile_or_compiled {
    # prompt user if they would like to build from source
    while true; do
        read -p "Would you like to build Vertcoin from source? " yn
        case $yn in 
            # if user says yes, call install_vertcoind to compile source
            [Yy]*   )   install_vertcoind; break;;
            # if user says no, grab latest vtc release and break from loop            
            [Nn]*   )   grab_vtc_release; break;;
        esac
    done
}

# config_vertcoin | create ~/.vertcoin/vertcoin.conf to configure vertcoind
function config_vertcoin {
    # echo values into a file named vertcoin.conf
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
}

# load_blockchain | prompt the user for input; would you like to sideload the
#                 | the vertcoin blockchain or grab the latest bootstrap.dat
function load_blockchain {
    # prompt user with menu selection
    PS3="Are you going to sideload the blockchain @ $LANIP:22? "
    options=("Yes, I will sideload the blockchain." "No, use bootstrap.dat instead." "No, sync on it's own.")
    select opt in "${options[@]}"
    do
        case $opt in
            "Yes, I will sideload the blockchain.")
                wait_for_continue 
                break       
                ;;
            "No, use bootstrap.dat instead.")
                grab_bootstrap                
                break                
                ;;
            "No, sync on it's own.")
                break                
                ;;
            * ) echo "Invalid option, please try again";;
        esac
    done
}

# prompt_p2pool | function to prompt user with option to install p2pool
function prompt_p2pool {
    while true; do
        echo
        read -p "Would you like install p2pool-vtc? " yn
        case $yn in 
            # if user says yes, call install_p2pool 
            [Yy]*   )   install_p2pool; break;;
            # if user says no, break from loop            
            [Nn]*   )   break;;
        esac
    done
}

# install_p2pool | function to download and configure p2pool
function install_p2pool {
    echo
    yellowtext 'Installing p2pool-vtc...'
    # install dependencies for p2pool-vtc
    sudo apt-get install python-rrdtool python-pygame python-scipy python-twisted python-twisted-web python-imaging python-pip libffi-dev -y
    # clone p2pool-vtc
    # grab latest p2pool-vtc release
    sudo -u "$user" wget "https://github.com/vertcoin-project/p2pool-vtc/archive/v0.3.0-rc1.zip"
    sudo -u "$user" unzip v0.3.0-rc1.zip
    sudo rm v0.3.0-rc1.zip
    cd "$userhome"/p2pool-vtc-0.3.0-rc1/
    sudo python setup.py install
    # download alternative web frontend and install
    echo
    yellowtext 'Installing alternate web frontend for p2pool-vtc...'
    echo
    cd "$userhome"/
    sudo -u "$user" git clone https://github.com/hardcpp/P2PoolExtendedFrontEnd.git
    cd "$userhome"/P2PoolExtendedFrontEnd/
    sudo -u "$user" mv * /home/$user/p2pool-vtc-0.3.0-rc1/web-static/
    cd "$userhome"/
    # clean up
    rm -r P2PoolExtendedFrontEnd/
    echo
    greentext 'Successfully installed alternate web frontend for p2pool-vtc!'
    echo
    getnewaddress=$(sudo -u $user vertcoin-cli getnewaddress "" legacy)
    # grab the LAN IP range and store it in variable network_address    
    network_address=$(ip -o -f inet addr show | awk '/scope global/{sub(/[^.]+\//,"0/",$4);print $4}')
    # open both ports for network 1 & network 2
    ufw allow 9171 comment 'allow --network 1 mining port'
    ufw allow 9181 comment 'allow --network 2 mining port'
    ufw allow 9346 comment 'allow --network 1 p2p port'
    ufw allow 9347 comment 'allow --network 2 p2p port'
    ufw --force enable
    ufw status
    # begin configuration of p2pool
    yellowtext 'Configuring p2pool-vtc...'
    echo
    echo "Network 1 | Recommended for large miners with hashrate larger than 100Mh"
    echo "Network 2 | Recommended for small miners with hashrate lower than 100Mh"
    # prompt user with menu for network selection
    echo
    PS3="What network do you want to configure with p2pool-vtc? "
    options=("Network 1" "Network 2")
    select opt in "${options[@]}"
    do
        case $opt in
            "Network 1")
                p2poolnetwork=""
                break       
                ;;
            "Network 2")
                p2poolnetwork="2"                
                break                
                ;;
            * ) echo "Invalid option, please select option 1 or 2.";;
        esac
    done
    # echo our values into a file named start-p2pool.sh
    echo "#!/bin/bash" >> /home/"$user"/start-p2pool.sh
    echo "cd p2pool-vtc-0.3.0-rc1" >> /home/"$user"/start-p2pool.sh
    echo "python run_p2pool.py --net vertcoin$p2poolnetwork -a $getnewaddress --max-conns 8 --outgoing-conns 4" >> /home/"$user"/start-p2pool.sh
    # permission the script for execution
    chmod +x start-p2pool.sh
    greentext 'Successfully configured p2pool-vtc!'
    echo
    yellowtext 'Starting p2pool-vtc...'
    cd "$userhome"/
    sudo -u "$user" nohup sh start-p2pool.sh &
}

# config_crontab | function to configure crontab to start 
function config_crontab {
    yellowtext 'Configuring Crontab...'
    yellowtext '- @reboot vertcoind -daemon'
    # store our command in variable cronjob
    cronjob="@reboot vertcoind -daemon"
    (crontab -u $user -l; echo "$cronjob" ) | crontab -u $user -
    echo
    greentext 'Successfully configured Crontab!'
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
    if [ "$key" = "secure" ]; 
    then
        secure; exit 1
    else
        redtext 'Unknown parameter'; exit 1
    fi
done
# call user_input function | take user input for rpcuser and rpcpass
clear
user_input
clear
greentext 'Starting Vertcoin full node installation, please be patient...'
greentext '______________________________________________________________'
# call update_rasp function | update the system
update_rasp
echo
# call install_depends function | install the required dependencies to run this script
install_depends
echo
# call secure function | modify iptables to limit connections for security purposes
secure
echo
# configure USB flash drive ; call hd_config function, then call swap_config function
if [ "$DRIVE_CONF" = "true" ]; then
    hd_config
    swap_config
fi
# call install_vertcoind | clone, build and install vertcoin core daemon
compile_or_compiled
echo
# call config_vertcoin | create ~/.vertcoin/vertcoin.conf to configure vertcoind
config_vertcoin
# prompt user to load blockchain
load_blockchain
greentext 'Starting Vertcoin Core...'
sudo -u "$user" vertcoind &
# sleep for 2 seconds
prompt_p2pool
# display post installation results
