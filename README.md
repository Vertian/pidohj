<p align="center">
  <img src="https://github.com/e-corp-sam-sepiol/Documentation/blob/master/images/vertcoin-branding.png" width="343" height="68" /> <img src="https://i.imgur.com/1RKi4wd.png" width="90">
</p>

#### Why a Vertcoin Full node?
Vertcoin is a digital currency supported by a peer-to-peer network. In order to run efficiently and effectively, it needs peers run by different people... and the more the better.

#### Why a Raspberry Pi?
Raspberry Pi is an inexpensive computing hardware platform that generates little heat, draws little power, and can run silently 24 hours a day without having to think about it.

`NOTE:` The steps provided in the `README` produce a “headless” server... meaning we will not be using a GUI to configure Vertcoin or check to see how things are running. In fact, once the server is set up, you will only interact with it using command line calls over `SSH`. The idea is to have this full node be simple, low-power, with optimized memory usage and something that “just runs” in your basement, closet, etc.

------------

# Vertnode 
## An automated solution for intalling Vertcoin node(s)
### Supported
- [x] **Raspberry Pi | Raspbian**
- [x] **Raspberry Pi Zero / Wireless | Raspbian** | **Testing in progress**

**`RECOMMENDED:` When you first boot your Raspberry Pi ensure that you `sudo apt-get update ; sudo apt-get upgrade -y ; sudo reboot` and `ssh` back into the Raspberry Pi before running the `install-vertnode.sh` script.**
```
git clone https://github.com/e-corp-sam-sepiol/vertnode.git
cd vertnode/
chmod +x install-vertnode.sh
sudo ./install-vertnode.sh 
```
### How to install Raspbian
**`Download Raspbian Stretch Lite`**
`https://www.raspberrypi.org/downloads/raspbian/`  

We will utilize the software 'Win32 Disk Imager' to format and install Raspbian on the MicroSD card. Please follow the [guide](https://www.raspberrypi.org/documentation/installation/installing-images/windows.md) below for details on installing the Rasbian image to the MicroSD card.

If you are using Linux please use [Etcher](https://etcher.io/)

![Write](https://i.imgur.com/fTyqpat.png)  
![Writing...](https://i.imgur.com/DrGi0mb.png)  
![Done](https://i.imgur.com/cfUjvKR.png)

Once Win32 Disk Imager is finished writing to the MicroSD card please access the 'boot' partition of the MicroSD card with Windows Explorer `Win+E`. Create a new empty text file named `ssh` like so...

![MicroSD card - ssh](https://i.imgur.com/m14rGdV.png)  
This enables `SSH` access on the Raspberry Pi's first boot sequence. 

### How to enable wireless connection on boot if hard wiring is not available

Create another new text file named `wpa_supplicant.conf` that will hold the network info...

Edit the file that you just created adjusting for the name of your country code, network name and network password.

```
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="NETWORK-NAME"
    psk="NETWORK-PASSWORD"
}
```
Please safely remove the USB Card Reader / MicroSD card as to ensure the data is not corrupted.

Insert the MicroSD card that was safely removed into the microSD slot the Raspberry Pi. Once the Pi has booted it will attempt to join the wireless network using the information provided in the `wpa_supplicant.conf` file.

### Functionality Checklist
- [x] Install dependencies
- [x] Modify `ufw` firewall rules for security
- [x] Find, format and configure USB flash drive
- [x] Create and configure swap space on USB flash drive
- [x] Download & compile Berkeley DB
- [x] Clone, build and install Vertcoin Core
- [x] Provide option to grab latest release rather than building from source
- [x] Added version detection for vertcoin release downloads based on system architecture
- [x] Configure `~/.vertcoin/vertcoin.conf`
- [x] Prompt to transfer blockchain
- [x] Provide option for `bootstrap.dat` sideload
- [x] Begin Vertcoin Sync
- [x] Provide option to install `p2pool-vtc`
- [x] Clone & build `p2pool-vtc`
- [x] Configure & launch `p2pool-vtc` 
- [x] Setup crontab job(s)
- [x] Display installation report
- [ ] Modify user input prompt to capture all user input at start of script
- [x] Script installation introduction, Vertcoin full node: what, why and how?
- [x] Add derived memory flag configuration based on RAM amount on hardware when building from source
- [x] Add hardware detection for Raspberry Pi Zero to ensure building from source to avoid segmentation fault
------------

### Instructions | How to use
* **Raspberry Pi 3**

**`RECOMMENDED:` When you first boot your Raspberry Pi ensure that you `sudo apt-get update ; sudo apt-get upgrade -y ; sudo reboot` and `ssh` back into the Raspberry Pi before running the `install-vertnode.sh` script.**
```
git clone https://github.com/e-corp-sam-sepiol/vertnode.git
cd vertnode/
chmod +x install-vertnode.sh
sudo ./install-vertnode.sh 
```

------------

### Functioning Status
- [x] **Success!** Raspberry Pi 3 B+ | ARM Cortex-A53 1.4GHz | 1GB SRAM | 

## Testing Errors

- [x] **Configuring firewall | Fixed with: `sudo reboot` then re-run `install_vertnode.sh`**

**`RECOMMENDED:` When you first boot your Raspberry Pi ensure that you `sudo apt-get update ; sudo apt-get upgrade -y ; sudo reboot` and `ssh` back into the Raspberry Pi before running the `install-vertnode.sh` script.**

**This error occurs when `sudo apt-get upgrade` installs a new kernel to the Raspberry Pi, it affects `iptables` which is a part of the kernel. Updating the kernel requires a reboot.**
```
ERROR: initcaps
[Errno 2] iptables v1.6.0: can't initialize iptables table `filter': Table does not exist (do you need to insmod?)
Perhaps iptables or your kernel needs to be upgraded.
```
------------
### Vertnode | Automated Vertcoin full node Installation Testing Results
- [x] Raspberry Pi 3 - **Installs Vertcoin full node** | **Installs p2pool-vtc node** | **Looks for USB flash drives (`sda`) for storage.** More testing to be done. Small amount of user input required. 
- [x] Raspberry Pi Zero W - Testing
- [ ] Intel NUC - Not tested

------------
### Raspberry Pi
#### Download Raspbian Stretch Lite
`https://www.raspberrypi.org/downloads/raspbian/`  

We will utilize the software 'Win32 Disk Imager' to format and install Raspbian on the MicroSD card. Please follow the [guide](https://www.raspberrypi.org/documentation/installation/installing-images/windows.md) below for details on installing the Rasbian image to the MicroSD card.

![Write](https://i.imgur.com/fTyqpat.png)  
![Writing...](https://i.imgur.com/DrGi0mb.png)  
![Done](https://i.imgur.com/cfUjvKR.png)

Once Win32 Disk Imager is finished writing to the MicroSD card please access the 'boot' partition of the MicroSD card with Windows Explorer `Win+E`. Create a new empty text file named `ssh` like so...

![MicroSD card - ssh](https://i.imgur.com/m14rGdV.png)  
This enables `SSH` access on the Raspberry Pi's first boot sequence. 



------------

### [Manual Installation Walkthrough: Raspberry Pi 3](https://github.com/vertcoin-project/VertDocs/blob/master/docs/FullNodes/raspberry-pi.md)
### [Manual Installation Walkthrough: Raspberry Pi Zero W](https://github.com/vertcoin-project/VertDocs/blob/master/docs/FullNodes/raspberry-pi-zero-w.md)
### [Manual Installation Walkthrough: Intel NUC](https://github.com/vertcoin-project/VertDocs/blob/master/docs/FullNodes/intel-nuc.md)

------------

<p align="center">
  <img src="https://i.imgur.com/zgx4uiu.jpg">
</p>
