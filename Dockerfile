FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y --no-install-recommends \
  build-essential \
  ca-certificates \
  curl \
  libgmp-dev \
  && rm -rf /var/lib/apt/lists/*

ENV GHCUP_INSTALL_BASE_PREFIX=/opt
ENV STACK_ROOT=/opt/.stack
ENV PATH="/home/dev/.local/bin:/opt/.ghcup/bin:${PATH}"

RUN groupadd -g 1000 dev && \
  useradd -m -u 1000 -g 1000 -s /bin/bash dev && \
  mkdir -p /opt/.ghcup ${STACK_ROOT} && \
  chown 1000:1000 /opt/.ghcup ${STACK_ROOT}

USER dev

ARG GHC_VERSION=9.10.3
ARG STACK_VERSION=latest
ARG HLS_VERSION=latest
ARG FOURMOLU_VERSION=0.20.0.0

RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | \
  BOOTSTRAP_HASKELL_NONINTERACTIVE=1 \
  BOOTSTRAP_HASKELL_MINIMAL=1 \
  sh && \
  ghcup config add-release-channel 3rdparty && \
  ghcup install ghc ${GHC_VERSION} --set && \
  ghcup install stack ${STACK_VERSION} --set && \
  ghcup install hls ${HLS_VERSION} --set && \
  ghcup install fourmolu ${FOURMOLU_VERSION} --set && \
  ghcup gc --cache --tmpdirs --hls-no-ghc && \
  rm -rf /opt/.ghcup/ghc/${GHC_VERSION}/share/doc /opt/.ghcup/logs && \
  stack config set system-ghc true --global && \
  stack config set install-ghc false --global
