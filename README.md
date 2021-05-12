<p align="center">
  <img src="https://github.com/vertiond/documents/blob/main/vertnode/pidohj.png" width="200" height="200" />
</p>

------------

# pidohj 
## An automated solution for installing Dogecoin node(s) on Single Board Computers and `amd64` compatible hardware

**`NOTE:` The steps provided below produce a “headless” server... meaning we will not be using a GUI to configure Dogecoin or check to see how things are running. In fact, once the server is set up, you will only interact with it using command line calls over `SSH`. The idea is to have this full node be simple, low-power, with optimized memory usage and something that “just runs” in your basement, closet, etc.**

**pidohj allows you to fast sync Dogecoin from a recent bootstrap or your own blocks data.  You may also sync from scratch.**

### Functioning Status
- [x] `Working` **Raspberry Pi 4** | Quad core Cortex-A72 1.5GHz | 2GB-8GB SDRAM |
- [x] `Working` **Raspberry Pi 3 B+** | ARM Cortex-A53 1.4GHz | 1GB SRAM | 
- [x] `Working` **Raspberry Pi Zero W** | Single Core ARMv6 1 Ghz | 433MB RAM |
- [ ] `Needs help updating` **Intel NUC** | Dual-Core 2.16 GHz Intel Celeron | 8GB DDR3 RAM |
- [ ] `Needs help updating` **Rock64 Media Board** | Quad-Core ARM Cortex A53 64-Bit CPU | 4GB LPDDR3 RAM | 
- [ ] `Needs help updating` **Orange Pi One** | H3 Quad-core Cortex-A7 1.2 GHz | 512MB RAM |

### **`USB flash drive required: >64GB - (128GB recommended)`**


### Supported
- [x] **Raspberry Pi 4 | [Raspberry Pi OS Lite](https://www.raspberrypi.org/software/operating-systems/)**
- [x] **Raspberry Pi | [Raspbian Stretch Lite](https://downloads.raspberrypi.org/raspbian_lite_latest/)**
- [x] **Raspberry Pi Zero / Wireless | [Raspbian Stretch Lite](https://downloads.raspberrypi.org/raspbian_lite_latest)** 
- [x] **Rock64 Media Board | [Debian Stretch Minimal](https://github.com/ayufan-rock64/linux-build/releases/download/0.6.15/stretch-minimal-rock64-0.6.15-175-arm64.img.xz)**
- [x] **Intel NUC | [Ubuntu Server 16.04](http://releases.ubuntu.com/16.04/ubuntu-16.04.4-server-amd64.iso)**
- [x] **Orange Pi One | [Armbian Stretch](https://dl.armbian.com/orangepione/Debian_stretch_next.7z) | [Getting Started](https://docs.armbian.com/User-Guide_Getting-Started/) |** `login` root `pass` 1234

---------------
### 1.) Parts List
|                                                              Name                                                             |        Price        |                                         URL                                        |
|:-----------------------------------------------------------------------------------------------------------------------------:|:-------------------:|:----------------------------------------------------------------------------------:|
|                                                           **Raspberry Pi of your choice**     | -------             | NOTE: Kits may come with some required hardware                                     |
| CanaKit Raspberry Pi Zero W (Wireless) Complete Starter Kit		             | $32.99 USD          | https://www.amazon.com/CanaKit-Raspberry-Wireless-Complete-Starter/dp/B072N3X39J/  |
| CanaKit Raspberry Pi 3 B+ Basic Kit                			                 | $59.99 USD          | https://www.amazon.com/CanaKit-Raspberry-Premium-Clear-Supply/dp/B07BC7BMHY/       |
| CanaKit Raspberry Pi 4 Basic Kit 			                 | $55-$90 USD         | https://www.amazon.com/CanaKit-Raspberry-Basic-Kit-8GB/dp/B07TYK4RL8/              |
|                                                      **Required hardware**     | -------             |                                                                                    |
| **MicroSD Memory Card** - Samsung 32GB 95MB/s (U1) MicroSD EVO Select Memory Card                        | $7.49 USD           | https://www.amazon.com/Samsung-MicroSD-Adapter-MB-ME32GA-AM/dp/B06XWN9Q99/         |
| **USB Flash Drive** - SanDisk Ultra Fit 128GB USB 3.1 Flash Drive                                    | $16.95 USD          | https://www.amazon.com/SanDisk-128GB-Ultra-Flash-Drive/dp/B07855LJ99               |
| **MicroSD Card Reader** - Transcend USB 3.0 SDHC / SDXC / microSDHC / SDXC Card Reader                   | $9.95 USD           | https://www.amazon.com/Transcend-microSDHC-Reader-TS-RDF5K-Black/dp/B009D79VH4/    |
| **[Sufficient Power Supply](https://www.raspberrypi.org/documentation/hardware/raspberrypi/power/README.md)**                   | ~ $10 USD           | -------    |
| *OPTIONAL: Case with Cooling Fan                                   | ~ $10 USD          | -------   |


------------------------
---------------

### 2.) Install Raspberry Pi OS Lite

>[Raspberry Pi OS](https://www.raspberrypi.org/documentation/raspbian/) is a free operating system based on Debian, optimised for the Raspberry Pi hardware. Raspberry Pi OS comes with over 35,000 packages: precompiled software bundled in a nice format for easy installation on your Raspberry Pi.

Download [Raspberry Pi Imager](https://www.raspberrypi.org/%20downloads/)   
Insert your MircoSD card into a USB MicroSD card reader and open Raspberry Pi Imager

Select [Raspberry Pi OS Lite (32-bit)](https://www.raspberrypi.org/software/operating-systems/), your target MicroSD card and Write!

![Choose-OS](https://github.com/vertiond/documents/blob/main/vertnode/raspberry-pi-imager.png)  
![Select-other](https://github.com/vertiond/documents/blob/main/vertnode/raspberry-pi-select-other.png)  
![Select-lite](https://github.com/vertiond/documents/blob/main/vertnode/raspberry-pi-os-lite.png)

Once Raspberry Pi Imager is finished writing to the MicroSD card please access the 'boot' partition of the MicroSD card with Windows Explorer `Win+E`. Create a new empty text file named `ssh` like so...

![MicroSD card - ssh](https://i.imgur.com/m14rGdV.png)  
This enables `SSH` access on the Raspberry Pi's first boot sequence. Please safely remove the USB Card Reader / MicroSD card as to ensure the data is not corrupted.

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

------------
### 3.) Initial Setup of Raspberry Pi

Insert the MicroSD card that was safely removed into the slot located on the bottom of the Raspberry Pi. Connect an Ethernet cable to the Raspberry Pi that has internet access. When you are ready to power on the Pi, plug the power supply in and the Raspberry Pi will immediately begin to boot.

We will access our Raspberry Pi through an `SSH` session on our Windows PC. I like to use `Git Bash` which is included in the Windows [download](https://git-scm.com/downloads) of `Git`.

Open a web browser, navigate to your router page and identify the `IP` address of the freshly powered on Raspberry Pi. In my case the `IP` address is `192.168.1.2`, please make note of your Raspberry Pi's `IP` address as we will need to use it to login via `SSH`.

Open `Git Bash` and ...  
`ssh 192.168.1.2 -l pi`   
Default password: `raspberry`

Change `user` password   
`passwd`

Change `root` password  
`sudo passwd root`

Download and install latest system updates  
`sudo apt update ; sudo apt upgrade -y ; sudo apt install git -y`

Download and install useful software packages   
`sudo apt install fail2ban -y`

>[Fail2ban](https://www.digitalocean.com/community/tutorials/how-fail2ban-works-to-protect-services-on-a-linux-server) is a daemon that can be run on your server to dynamically block clients that fail to authenticate correctly with your services repeatedly. This can help mitigate the affect of brute force attacks and illegitimate users of your services like `SSH`.

Initiate `raspi-config` script  
`sudo raspi-config`

```
1.) [8] Update				# update raspi-config script first
2.) [5] Localization Options       	
	> [L2] Change Timezone		# set your timezone
3.) [6] Advanced Options		
	> [A1] Expand Filesystem	# expand filesystem 
```
Use Tab to select `<Finish>` and choose to reboot.

Wait a minute, then log back in via `SSH`  
`ssh 192.168.1.2 -l pi`

------------
### 4.) Automated installation
**Ensure that you have an external USB drive that is >64GB attached**
```
git clone https://github.com/vertiond/pidohj && cd pidohj/
./install-pidohj.sh 
```
---------------
### FAQ

#### Why a Dogecoin node?
Dogecoin is a digital currency supported by a peer-to-peer network. In order to run efficiently and effectively, it needs peers run by different people... and the more the better.

#### Why a Raspberry Pi?
Raspberry Pi is an inexpensive computing hardware platform that generates little heat, draws little power, and can run silently 24 hours a day without having to think about it.

#### What is a Node?

Dogecoin’s peer-to-peer network is composed of network "nodes," run mostly by volunteers. Those running Dogecoin nodes have a direct and authoritative view of the Dogecoin blockchain, with a local copy of all the transactions, independently validated by their own system and can initiate transactions directly on the Dogecoin network.

By running a node, you don’t have to rely on any third party to validate a transaction. Moreover, **by running a Dogecoin node you contribute to the Dogecoin network by making it more robust**. A node client with the entire block archive consumes substantial computer resources (e.g., more than `50 GB` of disk, `~1 GB` of `RAM` at most) but offers complete autonomy and independent transaction verification.

**Running a node, however, requires a permanently connected system with enough resources to process all Dogecoin transactions.** Dogecoin nodes also transmit and receive Dogecoin transactions and blocks, consuming internet bandwidth. If your internet connection is limited, has a low data cap, or is metered (charged by the gigabit), you should probably not run a Dogecoin node on it, or run it in a way that limits its bandwidth usage.

Despite these resource requirements, thousands of volunteers run Dogecoin nodes. **Some are running on systems as simple as a [Raspberry Pi Zero](https://www.raspberrypi.org/products/raspberry-pi-zero/) (a $10 USD computer the size of a cracker)**. Many volunteers also run Dogecoin nodes on rented servers, usually some variant of Linux. A Virtual Private Server (VPS) or Cloud Computing Server instance can be used to run a Dogecoin node. Such servers can be rented for $10 to $50 USD per month from a variety of providers.

#### What is a Full Node?

A full node is one that optionally has port `22556` forwarded to your local IP on your router.  Both starting/external and ending/internal ports should be set to `22556` and external TCP is all that is necessary.  A full node will be able to accept incoming connections and serve archival block data to peers. Full nodes can connect with more peers than the default which allows for greater throughput of data on the Dogecoin network. This helps keep the Dogecoin peer-to-peer network healthy and strong.

#### Why run a headless node on a Single Board Computer?

1. You want to support Dogecoin. Running a node makes the network more robust and able to serve more wallets, more users, and more transactions.
2. You are building or using applications such as mining that must validate transactions according to Dogecoin’s consensus rules.
3. You are developing Dogecoin software and need to rely on a Dogecoin node for programmable (API) access to the network and blockchain.

**The idea is to have this node be simple, low-power, with optimized memory usage and something that “just runs” in your basement, closet, etc.**

---------------
### TO-DO Checklist
- [ ] adjust swap file size based on RAM
- [ ] expand support for x86_64 Debian / Ubuntu virtual machine, add option for USB flash drive
- [ ] add TOR network option

---------------

<p align="center">
  <img src="https://i.imgur.com/TKEVSFv.png">
</p>

<p align="center">
  <img src="https://images-na.ssl-images-amazon.com/images/I/91AAiPdhwxL._SL1500_.jpg">
</p>

<p align="center">
  <img src="https://cdn.shopify.com/s/files/1/0569/7173/products/Rock64Wood_2_1024x1024.jpg?v=1510970757">
</p>

<p align="center">
  <img src="https://i.imgur.com/zgx4uiu.jpg">
</p>

<p align="center">
  <img src="https://images-na.ssl-images-amazon.com/images/I/61NNweC8vCL._SL1448_.jpg">
</p>

<p align="center">
  <img src="https://i.imgur.com/9T0gKr7.png">
</p>
