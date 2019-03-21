IMAGE="${IMAGE:-sevenswen/crypticcoinubuntu18.04}"
docker run -e USER_ID=$(id -u $USER) -e GROUP_ID=$(id -g $USER) \
    -v $HOME/.crypticcoin/:/home/crypticuser/.crypticcoin:rw \
    -v $HOME/.crypticcoin-params/:/home/crypticuser/.crypticcoin-params:rw \
    --rm -it --name cryptic $IMAGE "$@"
