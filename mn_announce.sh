#!/usr/bin/env bash
# Masternode announcement helper script
#set -o errexit
set -o pipefail
set -o nounset

# Fill free to modify this section. 
# Set your addresses here, or leave them empty for autogeneration
###############################################################
# Masternode name, 3 to 31 letters:
name="$USER@$HOSTNAME masternode"
# P2PKH, must be unique:
ownerAuthAddress=${ownerAuthAddress:-""}
# P2PKH, must be unique:
operatorAuthAddress=${operatorAuthAddress:-""}
# P2PKH or P2SH
ownerRewardAddress=${ownerRewardAddress:-""}
# P2PKH or P2SH
operatorRewardAddress=${operatorRewardAddress:-""}
# P2PKH or P2SH
collateralAddress=${collateralAddress:-""}
# Number from 0 to 1. For example, 0.1 for 10%
operatorRewardRatio=${operatorRewardRatio:-"0"}
###############################################################

DOCKER_EXEC="docker exec -u crypticuser cryptic"
CLI_COMMAND="$DOCKER_EXEC crypticcoin-cli"

NODE_DIR=$HOME/.crypticcoin
CONFIG_FILE=$NODE_DIR/crypticcoin.conf
ERRFILE=/tmp/err.$$

function run_docker {
    IMAGE="${IMAGE:-sevenswen/crypticcoinubuntu18.04}"
    docker run -d -e USER_ID=$(id -u $USER) -e GROUP_ID=$(id -g $USER) \
        -v /home/$USER/.crypticcoin/:/home/crypticuser/.crypticcoin:rw \
        -v /home/$USER/.crypticcoin-params/:/home/crypticuser/.crypticcoin-params:rw \
        --rm -it --name cryptic $IMAGE "$@"
}

function run_docker_i {
    IMAGE="${IMAGE:-sevenswen/crypticcoinubuntu18.04}"
    docker run -e USER_ID=$(id -u $USER) -e GROUP_ID=$(id -g $USER) \
        -v /home/$USER/.crypticcoin/:/home/crypticuser/.crypticcoin:rw \
        -v /home/$USER/.crypticcoin-params/:/home/crypticuser/.crypticcoin-params:rw \
        --rm -it --name cryptic $IMAGE "$@"
}

function stop_docker {
    $DOCKER_EXEC pkill -f "crypticcoind" 2>$ERRFILE
}

function is_emptynode {
    if [ -z "$(ls -A $NODE_DIR)" ]; then
        return 0
    else
        return 1
    fi
}

function ensure_docker_stopped {
    for run in {1..3}
    do
        PSAX=$($DOCKER_EXEC ps ax 2>$ERRFILE)
        if cat $ERRFILE 2>/dev/null | grep -q "Error: No such container:" ; then
            return 0
        fi
        if echo "$PSAX" | grep -q crypticcoind; then
            echo "Ensure docker stopped: trying to stop crypticcoind"
            stop_docker
            sleep 5
            continue
        else
            # other process is running, just stop whole container
            echo "Ensure docker stopped: just stop container itself"
            docker stop cryptic >/dev/null
        fi
    done
    echo "Ensure docker stopped: can't stop docker, unknown error"
    exit 1
}

# Ensure crypticcoind in a container run:
function ensure_crypticcoind_run {
    # Ensure container run
    if $DOCKER_EXEC ps ax >/dev/null; then
        echo "Run cryptic container:  OK"
    else
        echo "Run docker image $IMAGE failed!"
        exit 1
    fi

    while $DOCKER_EXEC ps ax 2>$ERRFILE | grep -q fetch-params.sh
    do
        echo "Waiting for initial fetching sprout/sapling params. Keep calm."
        sleep 1
    done

    while ! $DOCKER_EXEC ps ax 2>$ERRFILE | grep -q crypticcoind
    do
        if cat $ERRFILE 2>/dev/null | grep -q "Error: No such container:"; then
            echo "Waiting for crypticcoind: unknown error"
            exit 1
        fi
        echo "Waiting for crypticcoind"
        sleep 1
    done
}

function wait_initialblockdownload {
    # Wait for initial blocks download:
    ERR_COUNT=0
    loading=$($CLI_COMMAND isinitialblockdownload 2>$ERRFILE)
    while [ "${loading}" != "false" ]
    do
    #        echo "loading = $loading"
        if [ "${loading}" == "true" ] ; then
            blocks=$($CLI_COMMAND getblockcount)
            echo "Waiting initial blocks download... (block: $blocks)"
            sleep 5
        elif cat $ERRFILE 2>/dev/null | grep -q "Loading block index" || \
             cat $ERRFILE 2>/dev/null | grep -q "Verifying blocks" || \
             cat $ERRFILE 2>/dev/null | grep -q "Verifying blocks" || \
             cat $ERRFILE 2>/dev/null | grep -q "Rewinding blocks if needed" || \
             cat $ERRFILE 2>/dev/null | grep -q "Loading wallet"
        then
            echo "$(tail -n 1 $ERRFILE)"
            sleep 1
        elif cat $ERRFILE 2>/dev/null | grep -q "Error: No such container:"; then
            # Everything was fine, but node has exit. Why? Reindex??
            if tail -n 20 $NODE_DIR/debug.log | grep -q "Aborted block database rebuild"; then
                echo "It looks like reindex needed. Try again please!"
            else
                echo "Unknown error! Exit!"
            fi
            exit 1
        else
            echo "$(tail -n 1 $ERRFILE)"
            if [ "$ERR_COUNT" -lt 10 ]; then
                let ERR_COUNT++
                sleep 1
                continue
            fi
            echo "Unknown error!"
            exit 1
        fi
        loading=$($CLI_COMMAND isinitialblockdownload 2>$ERRFILE)
    done
}

function check_address {
    if [ "${!1}" == "" ]
    then
        if result=$($CLI_COMMAND getnewaddress)
        then
            eval $1=$result
        fi
    fi
    echo "$1 = ${!1}"
}

############################# MAIN #####################################
if docker --version >/dev/null ; then
    echo "Checks 'docker' installed: OK"
else
    echo "Please install docker and try again"
    exit 1
fi

# remember, 1 means 'false' in bash
NEED_REINDEX=false

if is_emptynode; then
    echo "Start with empty node"
else
    echo "Start with non-empty node"
    ensure_docker_stopped

    if grep -q -E "(^masternode_operator)|(^masternode_owner)" $CONFIG_FILE; then
        echo "It looks like you are a masternode already! Are you sure you want to create new one?"
        echo "Delete 'masternode_operator' and 'masternode_owner' from $CONFIG_FILE and try again!"
    fi

    if grep -q "^txindex" $CONFIG_FILE; then
        if grep -q "^txindex=0" $CONFIG_FILE; then
            echo "Changing txindex=0 to txindex=1"
            sed -i -e 's/txindex=0/txindex=1/' $CONFIG_FILE
            NEED_REINDEX=true
        fi
    else
        echo "Adding txindex=1"
        printf "\ntxindex=1\n" >> $CONFIG_FILE
        NEED_REINDEX=true
    fi

    if tail -n 20 $NODE_DIR/debug.log | grep -q "Aborted block database rebuild"; then
        echo "Forcing reindex"
        NEED_REINDEX=true
    fi
fi

# Starting docker container
if $NEED_REINDEX; then
    run_docker_i fetch-params.sh
    run_docker crypticcoind -reindex
else
    run_docker
fi

sleep 3
ensure_crypticcoind_run
wait_initialblockdownload

##############################################################
echo "Trying to announce masternode with this parameters:"
echo
echo "name = ${name}"
check_address ownerAuthAddress
check_address operatorAuthAddress
check_address ownerRewardAddress
# We don't generate operatorRewardAddress!
echo "operatorRewardAddress = ${operatorRewardAddress}"
check_address collateralAddress
echo "operatorRewardRatio = ${operatorRewardRatio}"
echo

if id=$($CLI_COMMAND mn_announce [] "{\
\"name\":\"${name}\",\
\"ownerAuthAddress\":\"${ownerAuthAddress}\",\
\"operatorAuthAddress\":\"${operatorAuthAddress}\",\
\"ownerRewardAddress\":\"${ownerRewardAddress}\",\
\"operatorRewardAddress\":\"${operatorRewardAddress}\",\
\"operatorRewardRatio\":\"${operatorRewardRatio}\",\
\"collateralAddress\":\"${collateralAddress}\"\
}" 2>$ERRFILE)
then
    echo "Restarting..."
    ensure_docker_stopped
    printf "\nmasternode_owner=$ownerAuthAddress\n" >> $CONFIG_FILE
    printf "masternode_operator=$operatorAuthAddress\n" >> $CONFIG_FILE
    run_docker

    echo "Congratulations! You have announced new masternode"
    echo "with ID = $id"
    echo "You can get additional info after block will be mined using:"
    echo "$CLI_COMMAND mn_list [\\\"$id\\\"] true"
    echo
    echo "Don't forget to KEEP NODE RUNNING, or you will be resigned!!!"
    echo
else
    if grep "Insufficient funds!" $ERRFILE ; then
        echo "You should have at least $($CLI_COMMAND mn_estimateannouncementfee) on transparent addresses to announce a masternode!"
        echo "Now you have only $($CLI_COMMAND getbalance)"
    else
        echo "Error: $(tail -n 1 $ERRFILE)"
    fi
    ensure_docker_stopped
    echo "Done"
fi
