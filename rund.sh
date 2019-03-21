IMAGE="${IMAGE:-sevenswen/crypticcoinubuntu18.04}"
docker run -d -e USER_ID=$(id -u $USER) -e GROUP_ID=$(id -g $USER) \
    -v $HOME/$USER/.crypticcoin/:/home/crypticuser/.crypticcoin:rw \
    -v $HOME/$USER/.crypticcoin-params/:/home/crypticuser/.crypticcoin-params:rw \
    --rm -it --name cryptic $IMAGE "$@"
