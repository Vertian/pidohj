<p align="center">
  <img src="https://i.imgur.com/PJxYRgW.png" width="200" height="200" />
</p>

<p align="center">
  <img src="https://i.imgur.com/eJyg30C.png" width="343" height="68" />
</p>

# LIT Documentation

**`NOTE`** When working with multiple nodes running `lit` it is important to understand how the nodes are communicating. If you are attempting to run two `PoW-less` `lit` nodes then you will find that you must port forward the nodes on your router. You will find connectivity issues with the node not specified in the port forwarding, while you may be able to connect to the node that is port forwarded, you will not be able to connect to anything else but that using the node that is not port forwarded. 

This highlights the importance of running fully synced local instances of `vertcoind`. Running a `lit` node in `PoW-less` mode means that you are telling your node to rely on a remote node that is specified in the launch command i.e `https://vtc.blkidx.org/`. This means that your node is trusting that `vtc.blkidx.org` which runs an indexer of the Vertcoin blockchain is correct, this is the role a full node plays. That function gives the user the ability to completely, and trustlessly use the Vertcoin network when they have an entire history of the chain. `PoW-less` mode is handy for testing and playing with small amounts, using this while you are indexing the blockchain yourself is a way to get out of waiting around for your full node to come online.

### Indexers
* https://vtc.blkidx.org/

### Trackers
* http://hubris.media.mit.edu:46580/

### Remote Nodes
* `fr1.vtconline.org`

### Coin Types
* https://github.com/satoshilabs/slips/blob/master/slip-0044.md

Index | Hex       | Symbol | Coin
------|------------|--------|-----------------------------------
0     | 0x80000000 | BTC    | [Bitcoin](https://bitcoin.org/)
1     | 0x80000001 |        | Testnet (all coins)
2     | 0x80000002 | LTC    | [Litecoin](https://litecoin.org/)
28    | 0x8000001c | VTC    | Vertcoin

### Vertcoin Testnet

You can use the `vertcoind` process to connect to the Vertcoin testnet to play around with testnet `vtc`. It should be `NOTED` that the Vertcoin testnet be stuck at the point which you want to use the testnet. The solution is to CPU mine the blockchain, or have someone else CPU mine the blockchain. Normally this task would be difficult on the Bitcoin testnet due to ASIC manufactures testing their ASICs on the Bitcoin testnet.   

\# Run `vertcoind` in the background, use the testnet and prune the blockchain to `550MB`  
```
nuc@nuc:~$ vertcoind --daemon --testnet --prune=550
```
```
# EXAMPLES
# launch lit with the mainnet vertcoin network, use local vertcoind daemon (full node)
# pi@raspberrypi:~/go/src/github.com/mit-dci/lit $ ./lit -v --vtc localhost
#
# launch lit with powless mode using remote indexer
# pi@raspberrypi:~/go/src/github.com/mit-dci/lit $ ./lit -v --vtc https://vtc.blkidx.org/
```

--------------------------

#### Using `lit`   
* `./lit -v --vtc`      vertcoin mainnet
* `./lit -v --tvtc`     vertcoin testnet
* `./lit -v --lt4`      litecoin testnet
* `./lit -v --tn3`      bitcoin testnet

\#  **Recommended** Append `localhost` to the end to run `lit` using the locally running `vertcoind` process   
`./lit -v --vtc localhost`   

\# Append tracker URL to the end to run `lit` using a remote indexer for `lit`  
`./lit -v --vtc https://vtc.blkidx.org/`

#### Examples
```
# vertcoin mainnet using local full node, verbose console output
./lit -v --vtc localhost

# vertcoin mainnet using a remote indexer, verbose console output (powless)
./lit -v --vtc https://vtc.blkidx.org/

# vertcoin mainnet using remote full node, verbose console output  
./lit -v --vtc fr1.vtconline.org

# vertcoin mainnet, ask DNS seeds 
./lit --vtc 1 

# vertcoin testnet using local full node, verbose console output
./lit -v --tvtc localhost 
```

--------------------------

#### Using `lit-af`

\# Launch `lit-af`  
`./lit-af`  

#### `lit-af` Commands
* `ls` - list channels, addresses, peers and `UTXOs` 
* `lis` - start listening and retrieve a `lit` address
* `con` `<lit addr>` - connect to another lit node 
* `sweep` `<address to sweep to>` `<satoshi amount>` - sweep satoshis into your segwit address  
* `fund` `<peer id>` `<coin type>` `<channel capacity>` `<initial send>` - create a channel with a peer
* `push` `<channel id>` `<satoshi amount>` `<# of times>` - push satoshis in the channel you created
* `close` `<channel id>` - close the channel cooperatively, funds available after confirmation
* `break` `<channel id>` - close the channel uncooperatively, wait 2 days for access to coins
* `send` `<address>` `<satoshi amount>` - send specified amount of satoshis to the given address  
* `adr` `<?amount>` `<?cointype>` - create a new address 
* `history` - show all metadate for justice `txs`  
* `off` - shut down the `lit` node
* `exit` - exit the `lit-af` shell

**`NOTE`** 
* It will take a little while for lit to sync the various blockchains
* Omit any of the coin flags to not run that coin.

--------------------------

### Work in Progress 

##### Start `lit` node and connect with the `lit-af` shell
* `Terminal 1` `lit`  
* `Terminal 2` `lit-af`  
* `Second node` `Terminal 3` `lit`
* `Second node` `Terminal 4` `lit-af` 

![terminals](http://i.imgur.com/hixd4jV.png)


##### `ls` to see your channels, addresses, peers and `UTXOs`
```
lit-af# help ls

ls
Show various information about our current state, such as connections, addresses, UTXO's, balances, etc.
```
```
lit-af# ls
entered command: ls
	Addresses:
0 vtc1qmdzazpdwe408j7rwvy4255klqhkluk0vhshg9v (VuzEXf2FHFjxopLp6qvfNQtebvgYif92fL)
	Type: 28	Sync Height: 944471	FeeRate: 100	Utxo: 0	WitConf: 0 Channel: 0
	Type: 1	Sync Height: 1325138	FeeRate: 80	Utxo: 0	WitConf: 0 Channel: 0
```

* `send` Vertcoin to your non-segwit address. My address = `VuzEXf2FHFjxopLp6qvfNQtebvgYif92fL`  
* You must wait for confirmation on the Vertcoin network before it will populate in `ls`  
```
lit-af# ls
entered command: ls
	Peers:
1 76.XXX.XX.XX:52202
	Txos:
0 731c10469327202e0fd789c635f92331d9fa8c7d44d70ddeb59ba8bfde4a5b9a;0 h:944893 amt:49761700 /44'/28'/0'/0'/0' vtc non-witness
	Listening Ports:
Listening for connections on port(s) [:2448] with key ln13nj8cwxfah7crfx4fa4vuyw06sqm3fz08gug3j
	Addresses:
0 tb1qhg5xywdh7vgcawtwsmpkfecwl6ey6xmgm5q4pw (mxVGMeEDBEo6PmSKwmmAuEA85F34EjMe4g)
1 tb1q4terp9g79zge3xj5348vw76w52rxxmedfyh9f9 (mw6qJJgwTJsmhydUsu7BroobGRHVxmczP3)
2 vtc1qmdzazpdwe408j7rwvy4255klqhkluk0vhshg9v (VuzEXf2FHFjxopLp6qvfNQtebvgYif92fL)
	Type: 1	Sync Height: 1325243	FeeRate: 80	Utxo: 0	WitConf: 0 Channel: 0
	Type: 28	Sync Height: 944894	FeeRate: 100	Utxo: 49761700	WitConf: 0 Channel: 0
```
##### `sweep` satoshis into your segwit address  
```
lit-af# sweep vtc1qmdzazpdwe408j7rwvy4255klqhkluk0vhshg9v 49761700
entered command: sweep vtc1qmdzazpdwe408j7rwvy4255klqhkluk0vhshg9v 49761700
Swept
0 3adce916453fb7f306db6902022eae32c0b7f1b6afe33e593136bdaffe4093e1
```
##### `ls` to confirm the funds have been swept into a witness address
```
lit-af# ls
entered command: ls
	Peers:
1 76.XXX.XX.XX:52202
	Txos:
0 3adce916453fb7f306db6902022eae32c0b7f1b6afe33e593136bdaffe4093e1;0 h:944896 amt:49741700 /44'/28'/0'/0'/0' vtc
	Listening Ports:
Listening for connections on port(s) [:2448] with key ln13nj8cwxfah7crfx4fa4vuyw06sqm3fz08gug3j
	Addresses:
0 tb1qhg5xywdh7vgcawtwsmpkfecwl6ey6xmgm5q4pw (mxVGMeEDBEo6PmSKwmmAuEA85F34EjMe4g)
1 tb1q4terp9g79zge3xj5348vw76w52rxxmedfyh9f9 (mw6qJJgwTJsmhydUsu7BroobGRHVxmczP3)
2 vtc1qmdzazpdwe408j7rwvy4255klqhkluk0vhshg9v (VuzEXf2FHFjxopLp6qvfNQtebvgYif92fL)
	Type: 28	Sync Height: 944896	FeeRate: 100	Utxo: 49741700	WitConf: 49741700 Channel: 0
	Type: 1	Sync Height: 1325246	FeeRate: 80	Utxo: 0	WitConf: 0 Channel: 0
```
* `WitConf: 49741700` Success!

##### Troll your recipient 
```
lit-af# help say

say <peer> <message>
Send a message to a peer.
```
`peers` `1 76.XXX.XX.XX:52202`   
```
lit-af# say 1 "incoming vertcoin!"
entered command: say 1 "incoming vertcoin!"
```
```
lit-af#  
msg from 1: "incoming vertcoin!" 
```

##### Fund a channel with your recipient  
```
lit-af# help fund

fund <peer> <coinType> <capacity> <initialSend> [<data>]
Establish and fund a new lightning channel with the given peer.
The capacity is the amount of satoshi we insert into the channel,
and initialSend is the amount we initially hand over to the other party.
data is an optional field that can contain 32 bytes of hex to send as part of the channel fund
```
```
(...)
	Type: 1	Sync Height: 1325246	FeeRate: 80	Utxo: 0	WitConf: 0 Channel: 0
	Type: 28 Sync Height: 944897	FeeRate: 100	Utxo: 49741700	WitConf: 49741700 Channel: 0

lit-af# fund 1 28 49691700 0
entered command: fund 1 28 49691700 0
funded channel 1
```
```
lit-af# ls
entered command: ls
	Peers:
1 76.XXX.XX.XX:52224
	Channels:
Channel 1 (peer 1) type 28 a1a2d0da619c8b422b25ddf85e924b5d9c1cac70b8c70e77ad18319594094ba5;1
	 cap: 49691700 bal: 49691700 h: -1 state: 0 data: 0000000000000000000000000000000000000000000000000000000000000000 pkh: f5741e6ee97e6db0702abd126ac7cadc088c9c34
	Txos:
0 a1a2d0da619c8b422b25ddf85e924b5d9c1cac70b8c70e77ad18319594094ba5;0 h:0 amt:32200 /44'/28'/0'/0'/1' vtc
	Listening Ports:
Listening for connections on port(s) [:2448] with key ln13nj8cwxfah7crfx4fa4vuyw06sqm3fz08gug3j
	Addresses:
0 tb1qhg5xywdh7vgcawtwsmpkfecwl6ey6xmgm5q4pw (mxVGMeEDBEo6PmSKwmmAuEA85F34EjMe4g)
1 tb1q4terp9g79zge3xj5348vw76w52rxxmedfyh9f9 (mw6qJJgwTJsmhydUsu7BroobGRHVxmczP3)
2 vtc1qmdzazpdwe408j7rwvy4255klqhkluk0vhshg9v (VuzEXf2FHFjxopLp6qvfNQtebvgYif92fL)
3 vtc1qz5yqm9lpha0zhx36f95pca9pj7t00weawqh5t3 (Vbv2kH5hYRAQydE57HPfgWJ3pGjBDJz77J)
	Type: 1	Sync Height: 1325246	FeeRate: 80	Utxo: 0	WitConf: 0 Channel: 0
	Type: 28	Sync Height: 944901	FeeRate: 100	Utxo: 32200	WitConf: 0 Channel: 49691700
```
`Channel: 49691700` Success! Channel 1 now holds 49,691,700 satoshis! We can start to push our satoshis between
the nodes connected to the channel instantaneously, for `0` fees!

##### Push satoshis over the created channel
```
lit-af# help push

push <channel idx> <amount> [<times>] [<data>]
Push the given amount (in satoshis) to the other party on the given channel.
Optionally, the push operation can be associated with a 32 byte value hex encoded.
Optionally, the push operation can be repeated <times> number of times.
```
```
lit-af# push 1 1 10
entered command: push 1 1 10
push error: pushing 1 insufficient; counterparty bal 0 fee 100000 consts.MinOutput 100000

# push the fee amount in this case `100000` & with a minimum output `100000`
# you need to push the minimum amounts as well on the second host before you can push small amounts

lit-af# push 1 200000
entered command: push 1 200000
Pushed 200000 at state 0

# push 1 satoshi 10 times 
lit-af# push 1 1 10
entered command: push 1 1 10
Pushed 1 at state 1
Pushed 1 at state 2
Pushed 1 at state 3
Pushed 1 at state 4
Pushed 1 at state 5
Pushed 1 at state 6
Pushed 1 at state 7
Pushed 1 at state 8
Pushed 1 at state 9
Pushed 1 at state 10
```

--------------------------

### Commands  

#### `ls` - list channels, addresses, peers and `UTXOs` 
```
lit-af# ls
entered command: ls
	Addresses:
0 tb1qhg5xywdh7vgcawtwsmpkfecwl6ey6xmgm5q4pw (mxVGMeEDBEo6PmSKwmmAuEA85F34EjMe4g)
1 tb1q4terp9g79zge3xj5348vw76w52rxxmedfyh9f9 (mw6qJJgwTJsmhydUsu7BroobGRHVxmczP3)
2 vtc1qmdzazpdwe408j7rwvy4255klqhkluk0vhshg9v (VuzEXf2FHFjxopLp6qvfNQtebvgYif92fL)
	Type: 1	Sync Height: 1325238	FeeRate: 80	Utxo: 0	WitConf: 0 Channel: 0
	Type: 28	Sync Height: 944877	FeeRate: 100	Utxo: 0	WitConf: 0 Channel: 0
```
* `Type 1` = testnet bitcoin 
* `Type 28` = mainnet vertcoin 
* `Utxo` = the amount of unspent inputs our address(es) have, unspent satoshis 
* `WitConf` = the amount of confirmed satoshis in your segwit address 

The first two addresses listed `0` and `1` are bitcoin testnet addresses. The third line `2` lists
our mainnet vertcoin addresses. The `P2PKH` or `Pays To PubKey Hash` formatted address 
`VuzEXf2FHFjxopLp6qvfNQtebvgYif92fL` is the non-segwit address I must send vertcoin to if I plan on
creating a channel and pushing satoshis with another peer.  

Address `2` `vtc1qmdzazpdwe408j7rwvy4255klqhkluk0vhshg9v` `(VuzEXf2FHFjxopLp6qvfNQtebvgYif92fL)`

--------------------------

#### `lis` - start listening and retrieve a `lit` address 
```
lit-af# lis
entered command: lis
listening on ln13nj8cwxfah7crfx4fa4vuyw06sqm3fz08gug3j@:2448
```
* `lit` address = `ln13nj8cwxfah7crfx4fa4vuyw06sqm3fz08gug3j`  
* listening port = `2448`  

--------------------------

#### `con` - connect to another lit node 
```
lit-af# con ln13nj8cwxfah7crfx4fa4vuyw06sqm3fz08gug3j
entered command: con ln13nj8cwxfah7crfx4fa4vuyw06sqm3fz08gug3j
connected to peer ln13nj8cwxfah7crfx4fa4vuyw06sqm3fz08gug3j
```
* `lit` address to connect to = `ln13nj8cwxfah7crfx4fa4vuyw06sqm3fz08gug3j` (my raspberry pi)

`NOTE` If you are attempting to run `lit` on two seperate hosts on your network, you will need to port forward
one of the `lit` nodes at port `2448`. The `lit` node that is not port forwarded will not be able to `connect` 
to the specified `lit` address when given the command, this is because port `2448` on your router is not open 
and thus blocking the transmission of data on that port through the edge of your network. 

`Example` 
```
lit-af# con ln1u6gn0ye7rmy3wsd95y2z95tjsvnmacerzk32dh
entered command: con ln1u6gn0ye7rmy3wsd95y2z95tjsvnmacerzk32dh
con error: EOF
```
While the `lit` node that is not port forwarded on your router may not be able to `connect` outwards, you may
connect to it using your port forwarded `lit` node. 
```
lit-af# con ln13nj8cwxfah7crfx4fa4vuyw06sqm3fz08gug3j
entered command: con ln13nj8cwxfah7crfx4fa4vuyw06sqm3fz08gug3j
connected to peer ln13nj8cwxfah7crfx4fa4vuyw06sqm3fz08gug3j
```
Once connected to your `lit` node you will see new `peers` have populated the `ls` command output. This is 
possible due to one of the `lit` nodes being port forwarded, and connecting to the non-port forwarded host 
using the `lit` node that can communicate on that open port. 
```
lit-af# ls
entered command: ls
	Peers:
1 76.XXX.XX.XX:52202
	Listening Ports:
Listening for connections on port(s) [:2448] with key ln13nj8cwxfah7crfx4fa4vuyw06sqm3fz08gug3j
	Addresses:
0 tb1qhg5xywdh7vgcawtwsmpkfecwl6ey6xmgm5q4pw (mxVGMeEDBEo6PmSKwmmAuEA85F34EjMe4g)
1 tb1q4terp9g79zge3xj5348vw76w52rxxmedfyh9f9 (mw6qJJgwTJsmhydUsu7BroobGRHVxmczP3)
2 vtc1qmdzazpdwe408j7rwvy4255klqhkluk0vhshg9v (VuzEXf2FHFjxopLp6qvfNQtebvgYif92fL)
	Type: 1	Sync Height: 1325242	FeeRate: 80	Utxo: 0	WitConf: 0 Channel: 0
	Type: 28	Sync Height: 944885	FeeRate: 100	Utxo: 0	WitConf: 0 Channel: 0
```

--------------------------
