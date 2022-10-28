# Base
FROM debian:stable-slim AS base
ENV _BUILD_PATH="/build"
ENV _SOURCE_PATH="${_BUILD_PATH}/gcc-arm-src"
ENV _FILE_NAME="gcc-arm-src-snapshot-11.2-2022.02"
ENV _FILE="${_FILE_NAME}.tar.xz"
ENV _SOURCE="${_SOURCE_PATH}/${_FILE_NAME}"
ENV _PREFIX="/arm-gnu-toolchain"

FROM base AS src_code
# Source Code
## workspace
WORKDIR /workspace
RUN mkdir -p ${_BUILD_PATH}

## Download source code
RUN apt-get update
RUN apt-get install -y wget
RUN wget --https-only \
    "https://developer.arm.com/-/media/Files/downloads/gnu/11.2-2022.02/srcrel/gcc-arm-src-snapshot-11.2-2022.02.tar.xz"

## Extract
RUN apt-get install -y xz-utils
RUN mkdir -p ${_SOURCE_PATH} \
    && tar xvf \
        ${_FILE} \
        -C ${_SOURCE_PATH} \
    && rm ${_FILE}

FROM base AS builder
COPY --from=src_code ${_SOURCE_PATH} ${_SOURCE_PATH}

## Build deps
RUN apt-get update
RUN apt-get install -y build-essential
RUN apt-get install -y gcc-multilib
RUN apt-get install -y curl
WORKDIR "${_SOURCE}"
## Download prerequisites
RUN ./contrib/download_prerequisites
RUN apt-get install -y flex
## Outpath
RUN mkdir ${_PREFIX}
RUN ./configure --prefix=${_PREFIX}
RUN make -j $(nproc)
RUN make install

# main
FROM base AS main
COPY --from=builder ${_PREFIX} ${_PREFIX}

WORKDIR /workspace
ENV _PROFILE_PATH="/etc/profile"
RUN echo \
    "export PATH=${_PREFIX}/bin:\$PATH" \
    >> "${_PROFILE_PATH}"

ENTRYPOINT [ "bash", "-l"]
