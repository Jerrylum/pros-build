# Container image that runs your code
# FROM ubuntu:22.04
# FROM gcc:14.2.0

# -- Download toolchain --
FROM alpine:latest AS download-toolchain

RUN apk add --no-cache wget
RUN wget --no-verbose "https://developer.arm.com/-/media/Files/downloads/gnu/13.3.rel1/binrel/arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi.tar.xz" -O /tmp/gcc-arm-none-eabi.tar.xz
RUN mkdir -p /tmp/gcc-arm-none-eabi
RUN tar -xJf /tmp/gcc-arm-none-eabi.tar.xz -C /tmp/gcc-arm-none-eabi --strip-components=1 

# -- Install packages --
FROM alpine:latest AS final

RUN apk add --no-cache jq python3 pipx

RUN pipx install pros-cli==3.5.4
ENV PATH=/root/.local/bin:$PATH

COPY --from=download-toolchain /tmp/gcc-arm-none-eabi /usr/local/gcc-arm-none-eabi
ENV PATH=/usr/local/gcc-arm-none-eabi/bin:$PATH

# -- Verify toolchain --
# RUN python3 --version
# RUN pros --version
# RUN arm-none-eabi-g++ --version
# RUN arm-none-eabi-gcc --version

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]
