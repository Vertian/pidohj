<p align="center">
  <img src="https://github.com/e-corp-sam-sepiol/Documentation/blob/master/images/vertcoin-branding.png" width="343" height="68" /> <img src="https://i.imgur.com/1RKi4wd.png" width="90">
</p>

# Vertnode 
## An automated installation for Vertcoin full node(s) on a Raspberry Pi 3
- [x] Install dependencies
- [x] Modify `ufw` firewall rules for security
- [x] Find, format and configure USB flash drive
- [x] Create and configure swap space on USB flash drive
- [x] Download & compile Berkeley DB
- [x] Clone, build and install Vertcoin Core
- [x] Provide option to grab latest release rather than building from source
- [x] Configure `~/.vertcoin/vertcoin.conf`
* Prompt user that Pi is ready to be sideloaded with blockchain
- [x] Prompt to transfer blockchain
- [x] Provide option for `bootstrap.dat` sideload
- [x] Begin Vertcoin Sync
- [ ] Setup crontab jobs
- [x] Clone & build `p2pool-vtc`
- [ ] Configure & launch `p2pool-vtc` 
- [ ] Display installation report

### [Manual Installation Walkthrough: Raspberry Pi 3](https://github.com/vertcoin-project/VertDocs/blob/master/docs/FullNodes/raspberry-pi.md)
### [Manual Installation Walkthrough: Raspberry Pi Zero W](https://github.com/vertcoin-project/VertDocs/blob/master/docs/FullNodes/raspberry-pi-zero-w.md)
### [Manual Installation Walkthrough: Intel NUC](https://github.com/vertcoin-project/VertDocs/blob/master/docs/FullNodes/intel-nuc.md)
#### Automated Vertcoin Installation Testing
- [x] Raspberry Pi 3 - Installs a Vertcoin full node with little user input. Looks for USB flash drives <=16GB for storage. More testing to be done.
- [ ] Raspberry Pi Zero W - Not tested
- [ ] Intel NUC - Not tested

<p align="center">
  <img src="https://i.imgur.com/zgx4uiu.jpg">
</p>
