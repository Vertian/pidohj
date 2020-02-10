#!/bin/bash
#
# TESTING IN PROGRESS
#
# An automated script to assist with installing Dogecoin full node(s)
# -------------------------------------------------------------------
# AUTHORS:
# jochemin   | Twitter: @jochemin | BTC Donations --> 3FM6FypcrSVhdHh7cpVQMrhPXPZ6zcXeYU
# Sam Sepiol | Email: ecorp-sam.sepiol@protonmail.com 
# SPECIAL THANKS:
# Thanks @b17z, this fork would not have happened without you. Thanks
# for your help and inspiration. 
#
# Dedicated to the dogecoin community. 
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
#           install_dogecoind   | clone, build and install dogecoin core daemon
#           config_dogecoin     | create ~/.dogecoin/dogecoin.conf to configure dogecoind
#           install_depends     | install the required dependencies to run this script
#           grab_doge_release    | grab the latest dogecoind release from github
#           wait_for_continue   | function for classic "Press spacebar to continue..." 
#           grab_doge_release    | grab the latest dogecoind release from github
#           grab_bootstrap      | grab the latest bootstrap.dat from alwayshashing
#           compile_or_compiled | prompt the user for input; would you like to build dogecoin core 
#           load_blockchain     | prompt the user for input; would you like to sideload the chain or 
#                               | grab the latest bootstrap.dat
#           prompt_p2pool       | function to prompt user with option to install p2pool
#           install_p2pool      | function to download and configure p2pool
#           userinput_lit       | function to prompt user with option to install lit and lit-af
#           install_lit         | function to download and install golang, lit and lit-af
#           user_intro          | introduction to installation script, any key to continue
#           installation_report | report back key and contextual information
#           wait_for_continue   | function for classic "Press spacebar to continue..." 
#           config_crontab      | function to configure crontab to start 
# -------------------------------------------------------------------

# hinder root from running script
if [[ $EUID -eq 0 ]]; then
  echo "Please do not run this script as root." 1>&2
  exit 1
fi
# clear the screen to begin
clear
# install depends for detection; check for lshw, install if not
if [ $(dpkg-query -W -f='${Status}' lshw 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    echo "Installing required dependencies to run install-dogecoinnode..."    
    sudo apt-get install lshw -y
fi
# install depends for detection; check for gawk, install if not
if [ $(dpkg-query -W -f='${Status}' gawk 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    echo "Installing required dependencies to run install-dogecoinnode..."    
    sudo apt-get install gawk -y
fi
# install depends for detection; check for git, install if not
if [ $(dpkg-query -W -f='${Status}' git 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    echo "Installing required dependencies to run install-dogecoinnode..."    
    sudo apt-get install git -y
fi
# fail on error; debug all lines
set -eu -o pipefail
# colors for console output
TEXT_RESET='\e[0m'
TEXT_YELLOW='\e[0;33m'
TEXT_RED='\e[1;31m'
TEXT_GREEN='\e[0;32m'
# global script variables
user=$(logname)
userhome='/home/'$user
FOLD1='/dev/'
PUBLICIP="$(curl -s ipinfo.io/ip)"
KERNEL="$(uname -a | awk '{print $2}')"
# grab the first column of system name
SYSTEM="$(sudo lshw -short | grep system | awk -F'[: ]+' '{print $3" "$4" "$5" "$6" "$7" "$8" "$9" "$10" "$11}' | awk '{print}')"
# grab the default gateway ip address
GATEWAY="$(ip r | grep "via " | awk -F'[: ]+' '{print $3}')"
# grab the release name of operating system
RELEASE="$(cat /etc/*-release | gawk -F= '/^NAME/{print $2}' | tr -d '"')"
#'
RAM="$(cat /proc/meminfo | grep MemTotal | awk -F'[: ]+' '{print $2}')"
RAM_MIN='910000'
ARCH="$(dpkg --print-architecture)"
P2P=''
INSTALLP2POOL=''
INSTALL_LIT=''
BUILDDOGECOIN=''
LOADBLOCKMETHOD=''
MAXUPLOAD=''
# find the active interface
while true; do
    if [[ $SYSTEM = "Raspberry Pi Zero"* ]]; then
        # grab only the first row of data, user may want wifi + lan
        INTERFACE="$(ip -o link show | awk '{print $2,$9}' | grep UP | awk '{print $1}' | sed 's/:$//' | awk 'NR==1{print $1}')"
        break
    elif [[ $SYSTEM = "Rockchip"* ]]; then
        sudo apt-get install facter -y
        # grab only the first row of data, user may want wifi + lan
        INTERFACE="$(sudo facter 2>/dev/null | grep ipaddress_et | awk '{print $1}' | sed 's/.*_//' | awk 'NR==1{print $1}')"
        break
    else
        # grab only the first row of data, user may want wifi + lan
        INTERFACE="$(ip -o link show | awk '{print $2,$9}' | grep UP | awk '{print $1}' | sed 's/:$//' | awk 'NR==1{print $1}')"
        break
    fi
done
# check the active interface for its ip address
while true; do
    # check if system is a raspberry pi, grep for only inet if true, print the 2nd column
    if [[ $SYSTEM = "Raspberry"* ]]; then
        # grab ip address for raspberry pi    
        LANIP="$(ifconfig $INTERFACE | grep "inet " | awk -F'[: ]+' '{print $3}' | awk 'NR==1{print $1}')"
        break 
    elif [[ $SYSTEM = "Rockchip"* ]]; then
        # grab ip address for rock64 
        LANIP="$(sudo facter 2>/dev/null | grep ipaddress_et | awk '{print $3}')"
        break
    else
            if [[ $KERNEL = "orangepione" ]]; then  
                # grab ip address for orange pi one
                LANIP="$(sudo ifconfig $INTERFACE | grep "inet " | awk -F'[: ]+' '{print $3}' | awk 'NR==1{print $1}')"
            else
                # grap ip address for ubuntu
                LANIP="$(sudo ifconfig $INTERFACE | grep "inet addr" | awk -F'[: ]+' '{print $4}')"
            fi
        # do nothing        
        :
        break
    fi
done

# -----------------------------------

# network_addr | grab the LAN network address range of the host running this script
function network_addr {
    network_address=$(ip -o -f inet addr show | awk '/scope global/{sub(/[^.]+\//,"0/",$4);print $4}' | awk 'NR==1{print $1}')
}

# wait_for_continue | function for classic "Press spacebar to continue..." 
function wait_for_continue {
    echo 
    echo "DO NOT CONTINUE UNTIL THE BLOCKCHAIN HAS BEEN"
    echo "COMPLETELY COPIED OVER TO $userhome/.dogecoin/"
    echo
    read -n 1 -s -r -p "Press any key to continue..."
    echo
}

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

# user_intro | introduction to installation script, any key to continue
function user_intro {
    greentext 'Welcome to the Dogecoin node installation script!'
    echo
    greentext 'This script will install the Dogecoin software and allow for'
    greentext 'easy configuration of a Dogecoin full node.'
    echo 
    echo "To make this node a full node, please visit $GATEWAY with the"
    echo "URL bar of your web browser. Login to your router and continue"
    echo "to the port forwarding section and port forward..."
    echo "$LANIP TCP/UDP 22556"
    echo
    yellowtext 'What is a full node? It is a Dogecoin server that contains the'
    yellowtext 'full blockchain and propagates transactions throughout the Dogecoin'
    yellowtext 'network via peers. Playing its part to keep the Dogecoin peer-to-peer'
    yellowtext 'network healthy and strong.'
    echo
    read -n 1 -s -r -p "Press any key to continue..."
}

# user_input | take user input for rpcuser and rpcpass
function user_input {
    # check for USB flash drive
    while true; do
        clear
        echo -e "$TEXT_GREEN"
        read -p "Is the USB flash drive connected? It will be formatted. (y/n) " yn
        case $yn in
            [Yy]* ) hd_detect; break;;  # if we have hd_config value we can configure it
            [Nn]* ) echo "Please connect USB flash drive and retry."; exit;;
            * ) echo "Do you wish to continue? (y/n) ";;
        esac
    done
    clear
    echo -e "$TEXT_GREEN"
    echo 'Dogecoin requires both an rpcuser & rpcpassword, enter your preferred values: '
    read -p 'Enter RPC user: ' rpcuser
    read -s -p 'Enter RPC password: ' rpcpass
    clear    
    while true; do
        echo -e "$TEXT_GREEN"
        echo "What would you like the maximum amount of data (in MegaBytes) "
        echo "that you would like to allow your Dogecoin node to upload daily? "
        echo
        echo "Examples:"
        echo "          1024 = 1GB"
        echo "          2048 = 2GB"
        echo "          3072 = 3GB"
        echo "          4096 = 4GB"
        echo "          5120 = 5GB" 
        echo 
        read -p 'maxuploadtarget=' MAXUPLOAD
        # little bit of macgyvering here. this if statement uses -eq for something 
        # other then it was intended. it checks for an integer, if it doesnt 
        # find an one then it returns an error which is passed to /dev/null 
        # and a value of false.
        if [ $MAXUPLOAD -eq $MAXUPLOAD 2>/dev/null ]
            then
                # if MAXUPLOAD is an integer break from loop and continue
                break
            else
                echo "$MAXUPLOAD isn't a number. Please try again."
        fi
    done
}

# compile_or_compiled | prompt the user for input; would you like to build Dogecoin core 
#                     | from source or would you like to grab the latest release binary?
function compile_or_compiled {
    # if the system name contains RaspberryPiZero then compile from source
    # to avoid segmentation fault errors   
    while true; do
        if [[ $SYSTEM = "Raspberry Pi Zero"* ]]; then
            echo "**************************************************************************"           
            echo "HARDWARE = $SYSTEM"
            echo "Precompiled release binaries produce segmentation fault errors on $SYSTEM."
            echo
            echo "This script will build Dogecoin Core from source..."
            echo "NOTE: These operations will utilize the CPU @ 100% for a long time."
            echo "**************************************************************************"
            sleep 15
            BUILDDOGECOIN="install_dogecoind"
            break
        fi
        if [[ $SYSTEM = "Rockchip"* ]]; then
            echo "**************************************************************************"           
            echo "HARDWARE = $SYSTEM"
            echo "No precompiled releases are made available for $SYSTEM $ARCH."
            echo
            echo "This script will build Dogecoin Core from source..."
            echo "NOTE: These operations will utilize the CPU @ 100% for some time."
            echo "**************************************************************************"
            sleep 15
            BUILDDOGECOIN="install_dogecoind"
            break
        fi
        if [[ $KERNEL = "orangepione" ]]; then
            echo "**************************************************************************"           
            echo "HARDWARE = $KERNEL"
            echo "The latest release of Dogecoin will be utilized for $KERNEL $ARCH."
            echo
            echo "$KERNEL currently experiences issues building Dogecoin from source"
            echo "**************************************************************************"
            sleep 15
            BUILDDOGECOIN="grab_doge_release"
            break
        fi
            # prompt user if they would like to build from source
        read -p "Would you like to build Dogecoin from source? (y/n) " yn
        case $yn in 
            # if user says yes, call install_dogecoind to compile source
            [Yy]*   )   BUILDDOGECOIN="install_dogecoind"; break;;
            # if user says no, grab latest doge release and break from loop            
            [Nn]*   )   BUILDDOGECOIN="grab_doge_release"; break;;
        esac
    done
}

# load_blockchain | prompt the user for input; would you like to sideload the
#                 | the Dogecoin blockchain or grab the latest bootstrap.dat
function load_blockchain {
    # prompt user with menu selection
    echo
    PS3="Are you going to sideload the blockchain @ $LANIP:22 ? "
    options=("Yes, I will sideload the blockchain." "No, use bootstrap.dat instead." "No, sync on it's own.")
    select opt in "${options[@]}"
    do
        case $opt in
            "Yes, I will sideload the blockchain.")
                LOADBLOCKMETHOD="wait_for_continue"         
                break       
                ;;
            "No, use bootstrap.dat instead.")
                LOADBLOCKMETHOD="grab_bootstrap"
                break              
                ;;
            "No, sync on it's own.")
                LOADBLOCKMETHOD=""
                break         
                ;;
            * ) echo "Invalid option, please try again";;
        esac
    done
}

# init_script
function init_script {
    echo    
    greentext 'Initializing Dogecoin node installation script...' 
    echo
    yellowtext '****************************************************************'
    if [[ $BUILDDOGECOIN = "install_dogecoind" ]]; then
        yellowtext 'Dogecoin Installation      | Build from source'
    else
        yellowtext 'Dogecoin Installation      | Latest dogecoin release'    
    fi
    if [[ $LOADBLOCKMETHOD = "wait_for_continue" ]]; then
        yellowtext 'Blockchain Loading Method  | Sideload the blockchain'
    elif [[ $LOADBLOCKMETHOD = "grab_bootstrap" ]]; then
        yellowtext 'Blockchain Loading Method  | Grab latest bootstrap.dat'
    else
        yellowtext 'Blockchain Loading Method  | Sync on its own'  
    fi  
    yellowtext '****************************************************************'
    sleep 10
}

# update_rasp | update the system
function update_rasp {
    yellowtext 'Initializing system update...'
    sudo apt-get update
    sudo apt-get upgrade -y
    sudo apt-get autoremove -y
    greentext 'Successfully updated system!'
    echo
}

# install_depends | install the required dependencies to run this script
function install_depends {
    yellowtext 'Installing package dependencies...'
    sudo apt-get install -y build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils python3 libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev git fail2ban dphys-swapfile unzip python python2.7-dev
    greentext 'Successfully installed required dependencies!'
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
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow from $network_address to any port 22 comment 'allow SSH from local LAN'
    sudo ufw allow 22556 comment 'allow dogecoin core'
    sudo ufw --force enable
    sudo systemctl enable ufw
    sudo ufw status
    echo 
    greentext 'Successfully configured firewall!'
    echo 
}

# hd_detect | USB flash drive detect; prompt for formatting
function hd_detect {
    # grep the output of lsblk -dlnb for the sda device
    # pass it to awk and print the fourth column of that row
    # that value = the size of the sda device
    usbsize=$(lsblk -dlnb | grep sda | awk '{print $4}')
    # list block devices that are greater than or equal to 15GB, cut the first three characters
    # make sure the microSD card that holds raspbian is 8GB or smaller to ensure find_drive picks 
    # the correct block device.
    find_drive="$(lsblk -dlnb | awk '{if($3 == 1){print}}' | awk '{print $1}')"
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
            sudo umount -l "$drive" > /dev/null
        fi
    yellowtext 'Formatting USB flash drive...'
    # format usb disk as ext4 filesystem    
    sudo mkfs.ext4 -F "$drive" -L storage
    greentext 'Successfully formatted flash drive!'
    # locally declare UUID as the value given by blkid
    UUID="$(sudo blkid -o value -s UUID "$drive")"
    echo
    yellowtext 'Creating dogecoin data folder...'
    DOGEDIR='/home/'$user'/.dogecoin'
    mkdir -p "$DOGEDIR"
    yellowtext 'Modifying fstab configuration...'
    echo    
    sudo sed -i".bak" "/$UUID/d" /etc/fstab    
    sudo sh -c "echo 'UUID=$UUID  $DOGEDIR  ext4  defaults,noatime  0    0' >> /etc/fstab"
        if mount | grep "$drive" > /dev/null; then
            :
        else
            sudo mount -a
        fi
    sudo chmod 777 $DOGEDIR
    greentext 'Successfully configured USB flash drive!'
    echo
}

# swap_config | configure swap file to reside on formatted flash drive
function swap_config {
    # !! notify user the ability to begin sideloading blockchain
    yellowtext '********************************************************************'
    greentext ' NOTICE: Sideloading is now available'    
    echo
    echo " If you intend on sideloading the blockchain please use an " 
    echo " SFTP client such as WinSCP or FileZilla to copy the BLOCKS"
    echo " and CHAINSTATE folder to /home/$user/.dogecoin/"
    yellowtext '--------------------------------------------------------------------'
    greentext ' HOW TO CONNECT: '
    echo
    echo " Using WinSCP or FileZilla please connect to... "    
    echo 
    echo " IP Address: $LANIP"    
    echo " Port: 22 "
    echo " Username: $user "
    echo " Password: (pi default pass: raspberry)" 
    echo "           (rock64 default pass: rock64)"    
    yellowtext '********************************************************************'
    echo
    # continue and configure swap    
    yellowtext 'Configuring swap file to reside on USB flash drive...'
    mkdir -p /home/"$user"/.dogecoin/swap
    # dd will take a few minutes to complete
    echo 
    echo "This may take awhile, please be patient."
    dd if=/dev/zero of=/home/"$user"/.dogecoin/swap/swap.file bs=1M count=2148
    sudo chmod 600 /home/"$user"/.dogecoin/swap/swap.file
    sudo sed -i".bak" "/CONF_SWAPFILE/d" /etc/dphys-swapfile
    sudo sed -i".bak" "/CONF_SWAPSIZE/d" /etc/dphys-swapfile
    sudo sh -c "echo 'CONF_SWAPFILE=/home/$user/.dogecoin/swap/swap.file' >> /etc/dphys-swapfile"
    # set aside 2GB of memory for swap    
    sudo sh -c "echo 'CONF_SWAPSIZE=2048' >> /etc/dphys-swapfile"
    sudo mkswap /home/"$user"/.dogecoin/swap/swap.file
    sudo swapon /home/"$user"/.dogecoin/swap/swap.file
    sudo sh -c "echo '/home/$user/.dogecoin/swap/swap.file  none  swap  defaults  0    0' >> /etc/fstab"
    echo    
    greentext 'Successfully configured swap space!'
    echo
}

# install_berkeley | install berkeley database 5.1 for wallet functionality
function install_berkeley {
    yellowtext 'Installing Berkeley (5.1) database...'
    mkdir -p "$userhome"/bin
    cd "$userhome"/bin
    wget http://download.oracle.com/berkeley-db/db-5.1.29.NC.tar.gz
    tar -xzvf db-5.1.29.NC.tar.gz
    cd db-5.1.29.NC/build_unix/
    # check if system is rock64, specify build type if true
    if [[ $SYSTEM = "Rockchip"* ]]; then
        ../dist/configure --enable-cxx --build=aarch64-unknown-linux-gnu
    else
        ../dist/configure --enable-cxx
    fi
    make
    sudo make install
    # set the current environment berkeley db location
    export LD_LIBRARY_PATH="/usr/local/BerkeleyDB.5.1/lib/"
    # echo the same location into .bashrc for persistence
    echo 'export LD_LIBRARY_PATH=/usr/local/BerkeleyDB.5.1/lib/' >> /home/"$user"/.bashrc
    greentext 'Successfully installed Berkeley (5.1) database!'
    echo
}

# userinput_dogecoin | begin configuration, building and installation of dogecoin
function userinput_dogecoin {
    # check for user response to compile from source
    if [[ $BUILDDOGECOIN = "install_dogecoind" ]]; then
        # if user selected to compile dogecoin from source, then compile
        install_dogecoind
    else
        # grab latest doge release
        grab_doge_release   
    fi   
}

# install_dogecoind | clone, build and install dogecoin core daemon
function install_dogecoind {
    install_berkeley      
    # continue on compiling dogecoin from source
    yellowtext 'Installing Dogecoin Core...'
    rm -fR "$userhome"/bin/dogecoin
    cd "$userhome"/bin
    git clone https://github.com/dogecoin/dogecoin.git
    while true; do        
       if [[ $SYSTEM = "Rockchip"* ]]; then
                cd "$userhome"/bin/dogecoin/
                ./autogen.sh        
                ./configure CPPFLAGS="-I/usr/local/BerkeleyDB.5.1/include -O2" LDFLAGS="-L/usr/local/BerkeleyDB.5.1/lib" --enable-upnp-default --build=aarch64-unknown-linux-gnu             
                break
       elif [ "$RAM" -gt "$RAM_MIN" ]; then
                # if RAM is greater than 910MB configure without memory flags
                cd "$userhome"/bin/dogecoin/
                ./autogen.sh        
                ./configure CPPFLAGS="-I/usr/local/BerkeleyDB.5.1/include -O2" LDFLAGS="-L/usr/local/BerkeleyDB.5.1/lib" --enable-upnp-default 
                break
       else
                # if RAM is less than 910MB configure with memory flags
                cd "$userhome"/bin/dogecoin/
                ./autogen.sh 
                ./configure CPPFLAGS="-I/usr/local/BerkeleyDB.5.1/include -O2" LDFLAGS="-L/usr/local/BerkeleyDB.5.1/lib" --enable-upnp-default CXXFLAGS="--param ggc-min-expand=1 --param ggc-min-heapsize=32768" 
                break
        fi
    done
    cd "$userhome"/bin/dogecoin/
    make
    sudo make install
    greentext 'Successfully installed Dogecoin Core!'
    echo
}

# grab_doge_release | grab the latest dogecoind release from github
function grab_doge_release {
    if [[ $RELEASE = "Ubuntu" ]]; then
        sudo add-apt-repository ppa:bitcoin/bitcoin -y
        sudo apt-get update 
        sudo apt-get install libdb4.8-dev libdb4.8++-dev -y  
    fi
    # grab the latest version number; store in variable $VERSION
    export VERSION=$(curl -s "https://github.com/dogecoin/dogecoin/releases/latest" | grep -o 'tag/[v.0-9]*' | awk -F/ '{print $2}')
    # grab the latest version release; deviation in release naming scheme will break this
    # release naming scheme needs to be: 'dogecoin-(release#)-linux-armhf.tar.gz' to work
    wget https://github.com/dogecoin/dogecoin/releases/download/$VERSION/dogecoin-$VERSION-linux-$ARCH.zip
    tar -xzvf dogecoind-$VERSION-linux-$ARCH.tar.gz
    # clean up    
    rm dogecoind-$VERSION-linux-$ARCH.tar.gz
    # move dogecoin binaries to /usr/bin/ 
    cd dogecoin-$VERSION/bin
    sudo mv dogecoind dogecoin-tx dogecoin-cli /usr/bin/
    cd "$userhome"
    rm -r dogecoin-$VERSION
}

# grab_bootstrap | grab the latest bootstrap.dat
function grab_bootstrap {
    # check package manager for pv, install if not
    if [ $(dpkg-query -W -f='${Status}' pv 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
        sudo apt-get install pv
    fi
    cd $userhome
    # grab bootstrap.dat generated by rnicoll
    echo "Downloading latest bootstrap.dat by rnicoll..."
    # download boostrap.dat    
    wget https://bootstrap.sochain.com/ -o $userhome/.dogecoin/
    echo
    echo "Successfully downloaded bootstrap.dat!"
    echo
}

# config_crontab | function to configure crontab to start 
function config_crontab {
    dogeRON=$({ crontab -l -u $user 2>/dev/null; echo '@reboot dogecoind -daemon'; } | crontab -u $user - )
    echo    
    yellowtext 'Configuring Crontab...'
    yellowtext '** dogecoind  | start on reboot'
    $dogeRON
    echo
    greentext 'Successfully configured Crontab!'
}

# config_dogecoin | create ~/.dogecoin/dogecoin.conf to configure dogecoind
function config_dogecoin {
    # echo values into a file named dogecoin.conf
    echo "server=1" >> /home/"$user"/.dogecoin/dogecoin.conf
    echo "rpcuser=$rpcuser" >> /home/"$user"/.dogecoin/dogecoin.conf
    echo "rpcpassword=$rpcpass" >> /home/"$user"/.dogecoin/dogecoin.conf
    echo 'dbcache=100' >> /home/"$user"/.dogecoin/dogecoin.conf
    echo 'maxmempool=100' >> /home/"$user"/.dogecoin/dogecoin.conf
    echo 'maxorphantx=10' >> /home/"$user"/.dogecoin/dogecoin.conf
    echo 'maxmempool=50' >> /home/"$user"/.dogecoin/dogecoin.conf
    echo 'maxconnections=40' >> /home/"$user"/.dogecoin/dogecoin.conf
    echo "maxuploadtarget=$MAXUPLOAD" >> /home/"$user"/.dogecoin/dogecoin.conf
    echo 'usehd=1' >> /home/"$user"/.dogecoin/dogecoin.conf
    # configure permissions for user access
    cd "$userhome"/.dogecoin/
    sudo chmod 777 dogecoin.conf
}

# initiate_blockchain | take user response from load_blockchain and execute
function initiate_blockchain {
    if [[ $LOADBLOCKMETHOD = "wait_for_continue" ]]; then
        # if user selected to install p2pool, then install it
        wait_for_continue
        echo
        # wait two minutes to ensure dogecoin core is alive before moving on
        greentext 'Waiting two minutes for Dogecoin Core to start...' 
        echo
        greentext 'Starting Dogecoin Core...'
        echo
        if [[ $BUILDDOGECOIN="install_dogecoind" ]]; then
            # if dogecoin was built from source set berkeleydb path 
            # env variable was exported to .bashrc but not active until new terminal session
            export LD_LIBRARY_PATH="/usr/local/BerkeleyDB.5.1/lib/"
            dogecoind -daemon
            sleep 120 
        else
            # just launch dogecoin because dogecoin was compiled for us
            dogecoind -daemon 
            sleep 120 
        fi         
    elif [[ $LOADBLOCKMETHOD = "grab_bootstrap" ]]; then
        grab_bootstrap
        echo
        # wait two minutes to ensure dogecoin core is alive before moving on
        greentext 'Waiting two minutes for Dogecoin Core to start...' 
        echo
        greentext 'Starting Dogecoin Core...'
        echo
        if [[ $BUILDDOGECOIN="install_dogecoind" ]]; then
            # if dogecoin was built from source set berkeleydb path 
            # env variable was exported to .bashrc but not active until new terminal session
            export LD_LIBRARY_PATH="/usr/local/BerkeleyDB.5.1/lib/"
            dogecoind -daemon -loadblock=$userhome/.dogecoin/bootstrap.dat
            sleep 120 
        else
            # just launch dogecoin because dogecoin was compiled for us
            dogecoind -daemon -loadblock=$userhome/.dogecoin/bootstrap.dat
            sleep 120 
        fi
        sleep 120           
    else
        # else just sync dogecoin on its own
        echo
        # wait two minutes to ensure dogecoin core is alive before moving on
        greentext 'Waiting two minutes for Dogecoin Core to start...' 
        echo
        greentext 'Starting Dogecoin Core...'
        echo
        if [[ $BUILDDOGECOIN="install_dogecoind" ]]; then
            # if dogecoin was built from source set berkeleydb path 
            # env variable was exported to .bashrc but not active until new terminal session
            export LD_LIBRARY_PATH="/usr/local/BerkeleyDB.5.1/lib/"
            dogecoind -daemon        
            sleep 120 
        else
            # just launch dogecoin because dogecoin was compiled for us
            dogecoind -daemon 
            sleep 120 
        fi       
    fi 
}

# post installation_report | report back key and contextual information
function installation_report {
    echo
    echo "DOGECOIN NODE INSTALLATION SCRIPT COMPLETE"
    echo "-------------------------------------"
    echo "Public IP Address: $PUBLICIP"
    echo "Local IP Address: $LANIP"
    echo "Default Gateway: $GATEWAY"
    echo "dogecoin Data: $userhome/.dogecoin/"
    echo    
    echo "-------------------------------------"
    echo
    echo "To make this node a full node, please visit $GATEWAY with the"
    echo "URL bar of your web browser. Login to your router and continue"
    echo "to the port forwarding section and port forward..."
    echo "$LANIP TCP/UDP 22556"
    echo
    echo "What is a full node? It is a Dogecoin server that contains the"
    echo "full blockchain and propagates transactions throughout the Dogecoin"
    echo "network via peers). Playing its part to keep the Dogecoin peer-to-peer"
    echo "network healthy and strong."
    echo
    echo "Useful commands to know:"
    echo "------------------------------------------------------------------------------"
    echo " htop                                 | task manager / resource monitor"
    echo " ifconfig                             | display network interface IP addresses"
    echo " dogecoin-cli getblockchaininfo       | display blockchain information"
    echo " dogecoin-cli getblockcount           | display current number of blocks"
    echo " dogecoin-cli getconnectioncount      | display number of connections"
    echo " dogecoin-cli getnettotals            | display total number of bytes sent/recv"
    echo " dogecoin-cli getnewaddress           | generate bech32 (segwit) address"
    echo " dogecoin-cli getnewaddress "\"""\"" legacy | generate legacy address"
    echo
    echo " # display latest dogecoin log information: " 
    echo " tail -f ~/.dogecoin/debug.log"
    echo
    echo "------------------------------------------------------------------------------"
}

# -------------BEGIN-MAIN-------------------


# clear the screen
clear
user_intro
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
compile_or_compiled
clear
# prompt user to load blockchain
load_blockchain
clear
init_script
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
# call userinput_dogecoin and build from source or grab release
userinput_dogecoin
# configure crontab for dogecoin
config_crontab
# call config_dogecoin | create ~/.dogecoin/dogecoin.conf to configure dogecoind
config_dogecoin
# execute on blockchain loading method
initiate_blockchain
# display post installation results
installation_report
