# Container image that runs your code
# FROM ubuntu:22.04
# FROM gcc:14.2.0

FROM alpine:latest AS download-toolchain

RUN apk add --no-cache wget
RUN wget --no-verbose "https://developer.arm.com/-/media/Files/downloads/gnu/13.3.rel1/binrel/arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi.tar.xz" -O /tmp/gcc-arm-none-eabi.tar.bz2
RUN mkdir -p /tmp/gcc-arm-none-eabi
RUN tar -xjf /tmp/gcc-arm-none-eabi.tar.bz2 -C /tmp/gcc-arm-none-eabi --strip-components=1 

# Installs packages
FROM alpine:latest AS final

RUN apk add --no-cache jq python3 pipx

RUN pipx install pros-cli==3.5.4
ENV PATH=/root/.local/bin:$PATH

COPY --from=download-toolchain /tmp/gcc-arm-none-eabi /usr/local/gcc-arm-none-eabi
ENV PATH=/usr/local/gcc-arm-none-eabi/bin:$PATH

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]
