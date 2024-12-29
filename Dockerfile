# -- Download toolchain --
FROM alpine:latest AS download-toolchain

RUN apk add --no-cache wget
RUN wget --no-verbose "https://developer.arm.com/-/media/Files/downloads/gnu/13.3.rel1/binrel/arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi.tar.xz" -O /tmp/gcc-arm-none-eabi.tar.xz
RUN mkdir -p /tmp/gcc-arm-none-eabi
# do not extract the toolchain as the docker image will become too large (> 1.49GB)
# RUN tar -xJf /tmp/gcc-arm-none-eabi.tar.xz -C /tmp/gcc-arm-none-eabi --strip-components=1 

# -- Install packages --
FROM alpine:latest AS final

# See: https://community.platformio.org/t/docker-alpine-linux-arm-none-eabi-gcc-not-found/30626/5
RUN apk add --no-cache gcompat libc6-compat libstdc++
RUN apk add --no-cache jq python3 pipx make

RUN pipx install pros-cli==3.5.4
ENV PATH="/root/.local/bin:$PATH"

COPY --from=download-toolchain /tmp/gcc-arm-none-eabi.tar.xz /arm-none-eabi-toolchain.tar.xz
# extract the toolchain on runtime
ENV PATH="/arm-none-eabi-toolchain/bin:$PATH"

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]
