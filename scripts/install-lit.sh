#!/bin/bash
# install lit & lit-af
# IN DEVELOPMENT - NON-FUNCTIONING STATUS

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
function install_lit { 
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
            # grab amd64 arch
            curl -L -O https://dl.google.com/go/go1.10.3.linux-amd64.tar.gz
            tar -C /usr/local -xzf go1.10.3.linux-amd64.tar.gz
            break
        fi
    done
    # install golang
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /home/"$user"/.bashrc
    mkdir -p /home/$user/go
    echo 'export GOPATH=$HOME/go' >> /home/"$user"/.bashrc
    cd "$userhome"/
    source .bashrc
    echo    
    # display go version
    go version
    echo
    # install lit
    go get github.com/mit-dci/lit
    # ensure system has depends
    go get ./...
    cd "$userhome"/go/src/github.com/mit-dci/lit/
    # refresh from git repo before building    
    git pull
    # build lit
    go build
    # build lit-af
    cd "$userhome"/go/src/github.com/mit-dci/lit/cmd/lit-af/
    go build
    # copy lit-af to lit directory
    cp lit-af /home/$user/go/src/github.com/mit-dci/lit/
    # go home and create symlink to lit
    cd "$userhome"/
    ln -s /home/$user/go/src/github.com/mit-dci/lit/ lit
}

install_lit
