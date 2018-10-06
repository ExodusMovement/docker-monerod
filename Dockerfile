FROM ubuntu:16.04 AS builder

ENV BUILD_TAG 0.12.3.0

RUN apt update
RUN apt install -y --no-install-recommends \
  build-essential \
  ca-certificates \
  cmake \
  doxygen \
  graphviz \
  git \
  libboost-all-dev \
  libexpat1-dev \
  libldns-dev \
  liblzma-dev \
  libpcsclite-dev \
  libpgm-dev \
  libreadline6-dev \
  libsodium-dev \
  libssl-dev \
  libunbound-dev \
  libunwind8-dev \
  libzmq3-dev \
  pkg-config

RUN git clone --recursive https://github.com/monero-project/monero
RUN cd monero \
  && git checkout v$BUILD_TAG \
  && git submodule update \
  && mkdir build \
  && cd build \
  && cmake -D BUILD_TESTS=OFF -D CMAKE_BUILD_TYPE=release ../ \
  && make -j$(nproc) \
  && strip bin/*


FROM ubuntu:16.04

RUN apt update \
  && apt --no-install-recommends --yes install \
    ca-certificates \
    libboost-chrono1.58.0 \
    libboost-filesystem1.58.0 \
    libboost-program-options1.58.0 \
    libboost-regex1.58.0 \
    libboost-serialization1.58.0 \
    libboost-thread1.58.0 \
    libczmq3 \
    libpcsclite1 \
    libunbound2 \
  && apt clean \
  && rm -rf /var/lib/apt

COPY --from=builder /monero/build/bin/* /usr/local/bin/

RUN groupadd --gid 1000 monerod \
  && useradd --uid 1000 --gid monerod --shell /bin/bash --create-home monerod

USER monerod

EXPOSE 18080 18081 18082

ENV \
  MONEROD_ZMQ_RPC_BIND_IP=127.0.0.1 \
  MONEROD_ZMQ_RPC_BIND_PORT=18082 \
  MONEROD_CHECK_UPDATES=notify \
  MONEROD_P2P_BIND_IP=0.0.0.0 \
  MONEROD_P2P_BIND_PORT=18080 \
  MONEROD_RPC_BIND_IP=127.0.0.1 \
  MONEROD_RPC_BIND_PORT=18081 \
  MONEROD_ARGUMENTS=""

CMD exec monerod \
  --zmq-rpc-bind-ip $MONEROD_ZMQ_RPC_BIND_IP \
  --zmq-rpc-bind-port $MONEROD_ZMQ_RPC_BIND_PORT \
  --check-updates $MONEROD_CHECK_UPDATES \
  --p2p-bind-ip $MONEROD_P2P_BIND_IP \
  --p2p-bind-port $MONEROD_P2P_BIND_PORT \
  --rpc-bind-ip $MONEROD_P2P_BIND_IP \
  --rpc-bind-port $MONEROD_RPC_BIND_PORT \
  $MONEROD_ARGUMENTS
