What is it?
-----------

This software are the scripts to build and run [Crypticcoin](https://crypticcoin.io/) node in the [docker container](https://www.docker.com/)
You can build new image from scratch, or just run the the pre-built image from [DockerHub](https://cloud.docker.com/u/sevenswen/repository/list).

First, you should install docker software and download this scripts.
Also, if you are not a real 'root' user, you SHOULD add your current linux user to the 'docker' group and relogin. 
In the case you are not a real 'root', **you SHOULD NOT run docker commands under 'sudo'**! It will lead to conflicts in service scripts and file access rights! 

There is some handy scripts pack called "tools". You can get short help of its functions using ". tools help".


Running node image
------------------
You can run existing at [DockerHub](https://cloud.docker.com/u/sevenswen/repository/list) docker image with just
```
. tools run_i
```
or you can run it in "detached mode" to stay in the same terminal window:
```
. tools run_d
```
At the very first run, node will download some nesessary Crypticcoin zkSNARK parameters (900~1600M) and blockchain data.
Please, keep calm.

If you want to pass some parameters to starting node (for example, for reindexing), you can do it with 
```
. tools run_i crypticcoind -reindex
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
docker exec cryptic -datadir=/home/crypticuser/.crypticcoin getblockchaininfo
```
There's a short alias script named 'cli':
```
. tools cli getblockchaininfo
```


Stop node
---------
If you run the node interactively with ". tools run_i", you can just hit Ctrl+C to exit.
Or, if you run it detached with ". tools run_i", you can kill it with
```
. tools stop_d
```

Please, **do not use docker command 'docker stop cryptic'** to stop running node, or you have to recreate some node database indexes at every following start (it takes extra time).

You can run function 'ensure_stopped', which will try first to soft stop the node, overwise it will be terminated by 'docker stop'.
```
. tools ensure_stopped
```


Installing masternode
---------------------

If you want to be a "masternode", substitute YOUR-REWARD-ADDRESS with correct P2PKH or P2SH address and run:

```
ownerRewardAddress=YOUR-REWARD-ADDRESS wget -qO- https://raw.githubusercontent.com/crypticcoinvip/docker/master/tools | bash ; mn_announce
```
or just
```
ownerRewardAddress=YOUR-REWARD-ADDRESS . tools mn_announce
```

If you have no enough money on the **transparent** addresses of this node or if you are running a "clean" configuration (without existent ~/.crypticcoin and wallet.dat) - you will fail with "Insufficient funds" error. 
In this case the script will prompt you how much money you should provide for announcement.
Send announcement coins to the one of the transparent addresses of this (new) wallet an try again. 


Building your own image
-----------------------

You can build your own image (it takes very long time) with (don't forget '.' at the end):
```
docker build -t <imagename> .
```
You should prefer 'sevenswen/crypticcoinubuntu18.04' as the image name, or you will get troubles using ". tools" later (at least, you ought to use IMAGE=<your new image name> every time running ". tools" commands).

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
IMAGE=myimage ./run.sh
```

