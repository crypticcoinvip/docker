#!/bin/bash

#HOME_DIR=/home/crypticuser
#SHARE_DIR=$HOME_DIR/.crypticcoin
#PARAMS_DIR=$HOME_DIR/.crypticcoin-params

if [[ -z "$GROUP_ID" || -z "$USER_ID" ]]; then
    echo "You MUST set GROUP_ID and USER_ID environment variables! Exit"
    exit
fi
echo "Starting with GID: $GROUP_ID, UID: $USER_ID"

# Add local user
addgroup --gid $GROUP_ID crypticgroup
adduser --uid $USER_ID --gid $GROUP_ID --home $HOME_DIR --system crypticuser

# Check if shared .crypticcoin-params is empty or not (first run?)
if [ -z "$(ls -A $PARAMS_DIR)" ]; then
   echo "$PARAMS_DIR dir is empty. First run? Setting user rights"
   chown -R $GROUP_ID:$USER_ID $PARAMS_DIR
else
   echo "$PARAMS_DIR is not empty, keeping rights unchanged"
fi

# Check if shared .crypticcoin is empty or not (first run?)
if [ -z "$(ls -A $SHARE_DIR)" ]; then
   echo "Node shared dir is empty. Copying default config, setting rights..."
   cp $HOME_DIR/crypticcoin.conf $SHARE_DIR/
   chown -R $GROUP_ID:$USER_ID $SHARE_DIR
else
   echo "Node data is not empty, starting node as is..."
fi

if [[ -z "$@" ]]; then
    gosu $GROUP_ID:$USER_ID fetch-params.sh
    gosu $GROUP_ID:$USER_ID crypticcoind
else
    echo "Running custom command $@"
    gosu $GROUP_ID:$USER_ID "$@"
fi
