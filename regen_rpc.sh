#!/bin/bash

function genrandomtoken {
    echo -e $(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 26)
}

function ensure_file_eol {
    # place "\n" at EOF only if not exist (if empty file - stay empty)
    # note, that it will be different for OS X
    sed -i -e '$a\' "$1" 2>/dev/null
}

function regenrpc {
    CONFIG_FILE=$SHARE_DIR/crypticcoin.conf

    if grep -q "^rpcuser" $CONFIG_FILE; then
        sed -i -e "s/^rpcuser=.*$/rpcuser=$(genrandomtoken)/" $CONFIG_FILE
    else
        ensure_file_eol $CONFIG_FILE
        printf "rpcuser=$(genrandomtoken)\n" >> $CONFIG_FILE
    fi
   
    if grep -q "^rpcpassword" $CONFIG_FILE; then
        sed -i -e "s/^rpcpassword=.*$/rpcpassword=$(genrandomtoken)/" $CONFIG_FILE
    else
        ensure_file_eol $CONFIG_FILE
        printf "rpcpassword=$(genrandomtoken)\n" >> $CONFIG_FILE
    fi
}

regenrpc
