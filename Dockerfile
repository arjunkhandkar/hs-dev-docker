FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

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
ARG FOURMOLU_VERSION=0.20.0.0
ARG CABAL_VERSION=3.18.2.0
ARG GHCID_VERSION=0.8.9
ARG HLINT_VERSION=3.10
ARG WEEDER_VERSION=2.11.0

RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | \
  BOOTSTRAP_HASKELL_NONINTERACTIVE=1 \
  BOOTSTRAP_HASKELL_MINIMAL=1 \
  sh && \
  ghcup config add-release-channel 3rdparty && \
  ghcup install ghc ${GHC_VERSION} --set && \
  ghcup install stack ${STACK_VERSION} --set && \
  ghcup install cabal ${CABAL_VERSION} --set && \
  ghcup install fourmolu ${FOURMOLU_VERSION} --set && \
  ghcup install hlint ${HLINT_VERSION} --set && \
  stack config set system-ghc true --global && \
  stack config set install-ghc false --global && \
  export CABAL_DIR=/tmp/cabal && \
  cabal update && \
  cabal install ghcid-${GHCID_VERSION} weeder-${WEEDER_VERSION} \
    --installdir=/home/dev/.local/bin \
    --install-method=copy \
    --enable-executable-dynamic \
    --enable-executable-stripping && \
  ghcup rm cabal ${CABAL_VERSION} && \
  ghcup gc --cache --tmpdirs --share-dir --hls-no-ghc && \
  rm -f /opt/.ghcup/bin/ghcup && \
  find /opt/.ghcup/ghc/${GHC_VERSION}/lib -type f \( \
    -name '*_p.a' -o -name '*_p.hi' -o -name '*_p.o' \
    -o -name '*.dyn_o' -o -name 'libHSghc-${GHC_VERSION}*.a' -o -name 'haddock*' \
  \) -delete && \
  strip --strip-unneeded \
    /home/dev/.local/bin/* \
    /opt/.ghcup/bin/stack* \
    /opt/.ghcup/bin/hlint* \
    /opt/.ghcup/bin/fourmolu* 2>/dev/null || true && \
  rm -rf /tmp/cabal /tmp/* /opt/.ghcup/logs /opt/.ghcup/trash ~/.cache/cabal ~/.local/state/cabal && \
  du -sh /opt/.ghcup /opt/.ghcup/ghc/${GHC_VERSION}/lib /home/dev/.local/bin
