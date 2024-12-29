# Container image that runs your code
# FROM ubuntu:22.04
# FROM gcc:14.2.0

FROM alpine:latest AS download-toolchain

RUN apk add --no-cache wget
RUN wget --no-verbose https://developer.arm.com/-/media/Files/downloads/gnu-rm/10.3-2021.10/gcc-arm-none-eabi-10.3-2021.10-x86_64-linux.tar.bz2 -O /tmp/gcc-arm-none-eabi.tar.bz2
RUN mkdir -p /tmp/gcc-arm-none-eabi
RUN tar -xjf /tmp/gcc-arm-none-eabi.tar.bz2 -C /tmp/gcc-arm-none-eabi --strip-components=1 

FROM alpine:latest AS python3

# Installs packages
RUN apk add --no-cache python3

FROM python3 AS install-pros-cli

RUN apk add --no-cache pipx
RUN pipx install pros-cli
ENV PATH=/root/.local/bin:$PATH

COPY --from=download-toolchain /tmp/gcc-arm-none-eabi /usr/local/gcc-arm-none-eabi
ENV PATH=/usr/local/gcc-arm-none-eabi/bin:$PATH

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]
