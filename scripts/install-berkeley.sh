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

# install_berkeley | install berkeley database 4.8 for wallet functionality
function install_berkeley {
    yellowtext 'Installing Berkeley (4.8) database...'
    sudo -u "$user" mkdir -p "$userhome"/bin
    cd "$userhome"/bin
    sudo -u "$user" wget http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz
    sudo -u "$user" tar -xzvf db-4.8.30.NC.tar.gz
    cd db-4.8.30.NC/build_unix/
    # check if system is rock64, specify build type if true
    if [[ $SYSTEM = "Rockchip" ]]; then
        ../dist/configure --enable-cxx --build=aarch64-unknown-linux-gnu
    else
        ../dist/configure --enable-cxx
    fi
    make
    sudo make install
    # if the system is a rock64 export the location of berkeleydb
    if [[ $SYSTEM = "Rockchip" ]]; then
        # set the current environment berkeley db location
        export LD_LIBRARY_PATH=/usr/local/BerkeleyDB.4.8/lib/
        # echo the same location into .bashrc for persistence
        echo 'export LD_LIBRARY_PATH=/usr/local/BerkeleyDB.4.8/lib/' >> /home/"$user"/.bashrc
    else
        # do nothing
        :
    fi
    greentext 'Successfully installed Berkeley (4.8) database!'
    echo
}

install_berkeley
