#!/bin/bash
# script to install lit & lit-af
# dependencies: golang 1.8 >

# install depends for detection; check for git, install if not
if [ $(dpkg-query -W -f='${Status}' git 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    echo "Installing required dependencies to run install-lit..."    
    apt-get install git -y
fi

user=$(logname)
userhome='/home/'$user

# download and install new version of golang, lit and lit-af
function install_lit { 
    # install lit
    cd "$userhome"/
    git clone https://github.com/mit-dci/lit
    cd "$userhome"/lit/
    make
}

install_lit
