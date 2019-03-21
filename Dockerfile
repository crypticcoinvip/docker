FROM ubuntu:18.04
ARG NPROC=4
ARG CRYPTIC_URL=https://github.com/crypticcoinvip/CrypticCoin 
ARG CRYPTIC_VERSION=2.0.0

MAINTAINER integralTeam - feedback@crypticcoin.io

#ENV CRYPTIC_URL=https://github.com/crypticcoinvip/CrypticCoin 
#ENV CRYPTIC_VERSION=1.2.0 

ENV PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin

RUN export DEBIAN_FRONTEND=noninteractive \
    && export BUILD_DEPS='gcc git build-essential libtool autotools-dev automake pkg-config' \
    && set -e -x \
    && apt-get update \
    && apt-get install -y apt-utils \
    && apt-get install -y bsdmainutils software-properties-common \
    && apt-get install -y wget curl tor libgomp1 gosu \
    && mkdir -p /root/.ccache/ \
    && apt-get install -y ${BUILD_DEPS} \
    && rm -rf /var/lib/apt/lists/* \
    && git clone ${CRYPTIC_URL} crypticcoin && cd crypticcoin && git checkout ${CRYPTIC_VERSION} \
    && ./zcutil/build.sh -j${NPROC} \
    && /usr/bin/install -c ./src/crypticcoind ./src/crypticcoin-cli ./zcutil/fetch-params.sh -t /usr/local/bin/ \
    && rm -rf /crypticcoin \
    && rm -rf /root/.ccache \
    && apt-get purge -y --auto-remove ${BUILD_DEPS}

ENV HOME_DIR=/home/crypticuser
ENV SHARE_DIR=$HOME_DIR/.crypticcoin
ENV PARAMS_DIR=$HOME_DIR/.crypticcoin-params

# NOTE, that we don't create and use ANY users at build time! Just home dirs
RUN mkdir -p ${HOME_DIR}
# NOTE, do not move (!!!) params in build time! it will be doublesized!
#&& mv /root/.crypticcoin-params/ ${HOME_DIR}/

COPY crypticcoin.conf ${HOME_DIR}
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

VOLUME ${SHARE_DIR}
VOLUME ${PARAMS_DIR}
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
