#!/bin/bash

user=$(logname)
userhome='/home/'$user

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

# install_depends | install the required dependencies to run this script
function install_depends {
    yellowtext 'Installing package dependencies...'
    sudo apt-get install -y build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils python3 libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev git fail2ban dphys-swapfile unzip python python2.7-dev
    greentext 'Successfully installed required dependencies!'
    echo
}

# install_p2pool | function to download and configure p2pool
function install_p2pool {
    echo
    yellowtext 'Installing p2pool-vtc...'
    # install dependencies for p2pool-vtc
    sudo apt-get install python-rrdtool python-pygame python-scipy python-twisted python-twisted-web python-imaging python-pip libffi-dev -y
    # grab latest p2pool-vtc release
    cd "$userhome"/
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
    # sleep an additional 2 minutes to make sure vertcoind is alive and can give an address
    sleep 120
    echo "python run_p2pool.py --net vertcoin$p2poolnetwork -a $getnewaddress --max-conns 8 --outgoing-conns 4" >> /home/"$user"/start-p2pool.sh
    # permission the script for execution
    chmod +x start-p2pool.sh
    echo
    greentext 'Successfully configured p2pool-vtc!'
    echo    
    yellowtext 'Configuring Crontab...'    
    yellowtext '** p2pool-vtc | start on reboot'    
    # define p2poolcron variable and store command to echo new cronjob into crontab    
    P2POOLCRON=$({ crontab -l -u $user 2>/dev/null; echo "@reboot sleep 120; nohup sh /home/$user/start-p2pool.sh"; } | crontab -u $user - ) 
    # echo cronjob value into crontab
    $P2POOLCRON
    echo
    yellowtext 'Starting p2pool-vtc...'
    cd "$userhome"/
    sudo -u "$user" nohup sh start-p2pool.sh &
}

install_depends
install_p2pool
