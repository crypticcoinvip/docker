What is it?
-----------

This software are the scripts to build and run [Crypticcoin](https://crypticcoin.io/) node in the [docker container](https://www.docker.com/)
You can build new image from scratch, or just run existing at [DockerHub](https://cloud.docker.com/u/sevenswen/repository/list).

First, you should install docker software and download this scripts.
Also, you may add your current linux user to the 'docker' group, or you'll have to run all commands below with 'sudo'.


Running node image
------------------
You can run existing at [DockerHub](https://cloud.docker.com/u/sevenswen/repository/list) docker image with just
```
./run.sh
```
or you can run it in "detached mode" to stay in the same terminal window:
```
./rund.sh
```
At the very first run, node will download some nesessary Crypticcoin zkSNARK parameters (900~1600M) and blockchain data.
Please, keep calm.


Running 'cli' commands
----------------------
After the node is running (deployed), commands can be run on the node using 'docker exec' with 'crypticcoin-cli'. 
```
docker exec -u crypticuser cryptic crypticcoin-cli getblockchaininfo
```
There are short alias script named 'cli':
```
./cli getblockchaininfo
```


Stop node
---------
If you run the node interactively with "/run.sh", you can just hit Ctrl+C to exit.
Or, if you run detached with "/rund.sh", you should kill it with
```
./stop.sh
```
or
```
docker exec -u crypticuser cryptic pkill -f "crypticcoind"
```

Please, **do not use docker command 'docker stop cryptic'** to stop running node, or you have to recreate some node database indexes at every following start (it takes extra time).


Installing masternode
---------------------

If you want to be a "masternode", substitute YOUR-REWARD-ADDRESS with correct P2PKH or P2SH address and run:

```
wget -qO- https://raw.githubusercontent.com/crypticcoinvip/docker/master/mn_announce.sh | ownerRewardAddress=YOUR-REWARD-ADDRESS bash
```
If you have no enough money on the **transparent** addresses of this node or if you are running a "clean" configuration (without existent ~/.crypticcoin and wallet.dat) - you will fail with "Insufficient funds" error. 
Send announcement collateral to the one of the transparent addresses of this (new) wallet an try again. 


Building your own image
-----------------------

You can build your own image (it takes very long time) with (notify '.' at end of line):
```
docker build -t <imagename> .
```

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

