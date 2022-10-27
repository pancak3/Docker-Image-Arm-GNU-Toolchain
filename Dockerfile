# Base
FROM debian:stable-slim as base
FROM base as builder

# workspace
RUN mkdir -p /workspace
WORKDIR /workspace

# Download source code
RUN apt-get update
RUN apt-get install -y wget
RUN wget --https-only \
    "https://developer.arm.com/-/media/Files/downloads/gnu/11.2-2022.02/srcrel/gcc-arm-src-snapshot-11.2-2022.02.tar.xz"

# Extract
RUN apt-get install -y xz-utils
RUN mkdir gcc-arm-src \
    && tar xvf \
        gcc-arm-src-snapshot-11.2-2022.02.tar.xz \
        -C gcc-arm-src \
    && rm gcc-arm-src-snapshot-11.2-2022.02.tar.xz

## Build deps
RUN apt-get install -y build-essential
WORKDIR /workspace/gcc-arm-src/gcc-arm-src-snapshot-11.2-2022.02
## Download prerequisites
RUN ./contrib/download_prerequisites
RUN apt-get install -y flex
## Outpath
ENV _PREFIX=/workspace/toolchain
RUN mkdir ${_PREFIX}
RUN ./configure --prefix=${_PREFIX}
RUN make -j $(nproc)
RUN make install

# Clean
RUN apt-get autoremove -y
RUN rm -rf /var/lib/apt/lists/*
RUN rm -rf /workspace/gcc-arm-src
RUN echo \
    "export PATH=/workspace/toolchain/bin:$PATH" \
    >> "/etc/profile"

WORKDIR /workspace
ENTRYPOINT [ "bash", "-l"]
