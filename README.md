What is it?
-----------

This software are the scripts to build and run [Crypticcoin](https://crypticcoin.io/) node in the [docker container](https://www.docker.com/)
You can build new image from scratch, or just run the the pre-built image from [DockerHub](https://cloud.docker.com/u/sevenswen/repository/list).

First, you should install docker software and download this scripts.
1. Install docker on your machine. On Ubuntu 16.04/18.04:
```
cat /etc/apt/sources.list # check that universe repo is enabled
sudo apt-get update
sudo apt-get docker.io
```
2. Download scripts
```
cd $HOME
git clone https://github.com/crypticcoinvip/docker.git
```

3. Also, if you are not a real 'root' user, you SHOULD add your current linux user to the 'docker' group and relogin after it. 
```
sudo usermod -a -G docker your-current-user # relogin after it!
```
In the case you are not a real 'root', **you SHOULD NOT run docker commands under 'sudo'**! It will lead to conflicts in service scripts and file access rights! 

There is some handy scripts pack called "tools". You can get short help of its functions using "./tools help".

After deploying the cryptic node, don't forget to place it at system start - manually, or by using
```
./tools set_autostart
```
This script will try to place starting record in "/etc/cron.d/cryptic_by_$USER". 
In the case you have **successfully** announced masternode by "./tools mn_announce", autostart will be set by announce script (and only in that case).
Anyway, make sure that node starts after system reboot. Especially in the case you are a "masternode"!

Running node image
------------------
You can run existing at [DockerHub](https://cloud.docker.com/u/sevenswen/repository/list) docker image with just
```
./tools run_i
```
or you can run it in "detached mode" to stay in the same terminal window:
```
./tools run_d
```
At the very first run, node will download some nesessary Crypticcoin zkSNARK parameters (900~1600M) and blockchain data.
Please, keep calm.

If you want to pass some parameters to starting node (for example, for reindexing), you can do it with 
```
./tools run_i crypticcoind -reindex
```
Note, that in this case, there will be no checks of fetched sapling|sprout data. Please, do not use it in the very first run!


Update docker image 
-------------------

If you need or somebody tells you to do so, you can update existing docker image with 
```
docker pull sevenswen/crypticcoinubuntu18.04
```


Running 'cli' commands
----------------------
After the node is running (deployed), CLI commands could be passed using 'docker exec' with 'crypticcoin-cli', but it's a bit long/unhandy:
```
docker exec cryptic_by_$USER -datadir=/home/crypticuser/.crypticcoin getblockchaininfo
```
(Don't be confused with '-datadir' path - it is the path inside container)

There's a short alias script named 'cli':
```
./tools cli getblockchaininfo
```
If it fails, but you are sure that you have run docker (by 'run_d'), you can issue special command to check/wait node is ready fo CLI commands:
```
./tools wait_run  # Waits until node run ('crypticcoind' process started). Container should be started before by 'run_d'
./tools wait_init # Waits until node init and ready for 'cli' commands
```


Stop node
---------
If you run the node interactively with "./tools run_i", you can just hit Ctrl+C to exit.
Or, if you run it detached with "./tools run_d", you can kill it with
```
./tools stop_d
```

Please, **do not use docker command 'docker stop cryptic_by_$USER'** to stop running node, or you have to recreate some node database indexes at every following start (it takes extra time).

You can run function 'ensure_stopped', which will try first to soft stop the node, overwise it will be terminated by 'docker stop'.
```
./tools ensure_stopped
```


Installing masternode
---------------------

If you want to be a "masternode", substitute YOUR-REWARD-ADDRESS with correct P2PKH or P2SH address and run:

```
wget -qO- https://raw.githubusercontent.com/crypticcoinvip/docker/master/tools | ownerRewardAddress=YOUR-REWARD-ADDRESS bash /dev/stdin mn_announce
```
or just
```
ownerRewardAddress=YOUR-REWARD-ADDRESS ./tools mn_announce
```

If you have no enough money on the **transparent** addresses of this node or if you are running a "clean" configuration (without existent ~/.crypticcoin and wallet.dat) - you will fail with "Insufficient funds" error. 
In this case the script will prompt you how much money you should provide for announcement.
Send announcement coins to the one of the transparent addresses of this (new) wallet an try again. 


Masternode Announcement Warnings
--------------------------------
1. The announcement operation **WILL BURN ANNOUNCEMENT FEE!** Don't do it you're not sure.
You can check announcement fee amount by "mn_estimateannouncementfee" CLI command ("./tools cli mn_estimateannouncementfee").

2. It is **VERY IMPORTANT** do not make ANY transactions from masternode wallet until announcement transaction got into the blockchain.
It can take more than one block so keep patience.
You should check that announcement is completed by "mn_list" CLI command ("./tools cli mn_list").
Overwise you can occasionally spend announcement collateral and so resign the masternode immidiately after announcement.
After the announcement tx got into blockchain your collateral will be protected from casual spend.


Resigning masternode
--------------------

If you want to resign your masternode, run this CLI command (on a running node, of cause):
```
./tools cli mn_resign MASTERNODE_ID new_t-address
```
where: MASTERNODE_ID is equal to the id of your announcement transaction,
new_t-address - a transparent addresss where your collateral will be sent.


Building your own image
-----------------------

You can build your own image (it takes very long time) with (don't forget '.' at the end):
```
docker build -t <imagename> .
```
You should prefer 'sevenswen/crypticcoinubuntu18.04' as the image name, or you will get troubles using "./tools" later (at least, you ought to use IMAGE=<your new image name> every time running "./tools" commands).

Default parameters are:
```
NPROC=4 
CRYPTIC_URL=https://github.com/crypticcoinvip/CrypticCoin
CRYPTIC_VERSION=2.0.0
```
You can override them, running with --build-arg, for example (building old version with 8 threads):
```
docker build --build-arg NPROC=8 --build-arg CRYPTIC_VERSION=1.1.2 -t myimage .
```
Then you can run it with:
```
IMAGE=myimage ./tools run_d (or run_i)
```

