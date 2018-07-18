#!/bin/bash
# bash script to install golang

# install depends for detection; check for lshw, install if not
if [ $(dpkg-query -W -f='${Status}' lshw 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    echo "Installing required dependencies to run install-lit..."    
    apt-get install lshw -y
fi

# install depends for detection; check for git, install if not
if [ $(dpkg-query -W -f='${Status}' git 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    echo "Installing required dependencies to run install-lit..."    
    apt-get install git -y
fi

user=$(logname)
userhome='/home/'$user
SYSTEM="$(lshw -short | grep system | awk -F'[: ]+' '{print $3" "$4" "$5" "$6" "$7" "$8" "$9" "$10" "$11}' | awk '{print $1}')"

# download and install new version of golang, lit and lit-af
function install_go { 
    # go home first
    cd "$userhome"/
    while true; do
        # check if system is a raspberry pi, grep for only inet if true, print the 2nd column
        if [[ $SYSTEM = "Raspberry" ]]; then
            # grab armhf arch for raspberry pi  
            curl -L -O https://dl.google.com/go/go1.10.3.linux-armv6l.tar.gz
            tar -C /usr/local -xzf go1.10.3.linux-armv6l.tar.gz
            break 
        elif [[ $SYSTEM = "Rockchip" ]]; then
            # grab arm64 arch for rock64 
            curl -L -O https://dl.google.com/go/go1.10.3.linux-arm64.tar.gz
            tar -C /usr/local -xzf go1.10.3.linux-arm64.tar.gz
            break
        else
                if [[ $KERNEL = "orangepione" ]]; then  
                    curl -L -O https://dl.google.com/go/go1.10.3.linux-armv6l.tar.gz
                    tar -C /usr/local -xzf go1.10.3.linux-armv6l.tar.gz
                else
                    # grab amd64 arch
                    curl -L -O https://dl.google.com/go/go1.10.3.linux-amd64.tar.gz
                    tar -C /usr/local -xzf go1.10.3.linux-amd64.tar.gz
                fi
            # do nothing        
            :
            break
        fi
    done
    # echo enviornment variables to .bashrc which is loaded on each new shell
    #echo 'export PATH=$PATH:/usr/local/go/bin' >> /home/"$user"/.bashrc
    sudo -u "$user" mkdir -p /home/$user/go
    #echo 'export GOPATH=$HOME/go' >> /home/"$user"/.bashrc
    # export environment variables to current shell     
    export GOPATH=$HOME/go    
    export PATH=$PATH:/usr/local/go/bin
    # display go version
    go version
}

install_go
