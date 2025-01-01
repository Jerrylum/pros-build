# -- Download toolchain --
FROM alpine:latest AS download-toolchain

RUN apk add --no-cache wget
RUN wget --no-verbose "https://developer.arm.com/-/media/Files/downloads/gnu/13.3.rel1/binrel/arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi.tar.xz" -O /tmp/arm-none-eabi-toolchain.tar.xz
RUN mkdir -p /arm-none-eabi-toolchain
RUN tar -xJf /tmp/arm-none-eabi-toolchain.tar.xz -C /arm-none-eabi-toolchain --strip-components=1

# -- Remove unnecessary files --
# "share" directory contains documentation and samples
RUN rm -rf /arm-none-eabi-toolchain/share
# Remove all thumb directories except v7-a+fp
RUN find /arm-none-eabi-toolchain/lib/gcc/arm-none-eabi/13.3.1/thumb -mindepth 1 -maxdepth 1 ! -name 'v7-a+fp' -exec rm -rf {} + 
# Remove all thumb directories except v7-a+fp
RUN find /arm-none-eabi-toolchain/arm-none-eabi/lib/thumb -mindepth 1 -maxdepth 1 ! -name 'v7-a+fp' -exec rm -rf {} +
# Remove all thumb directories except v7-a*
RUN find /arm-none-eabi-toolchain/arm-none-eabi/include/c++/13.3.1/arm-none-eabi/thumb -mindepth 1 -maxdepth 1 ! -name 'v7-a*' -exec rm -rf {} +
# Remove duplicate gcc
RUN rm /arm-none-eabi-toolchain/bin/arm-none-eabi-gcc-13.3.1
# Remove gdb debugger
RUN rm /arm-none-eabi-toolchain/bin/arm-none-eabi-gdb*

# -- Install packages --
FROM --platform=linux/amd64 alpine:latest AS runner

# See: https://community.platformio.org/t/docker-alpine-linux-arm-none-eabi-gcc-not-found/30626/5
RUN apk add --no-cache gcompat libc6-compat libstdc++
RUN apk add --no-cache jq python3 pipx make

RUN pipx install pros-cli==3.5.4
ENV PATH="/root/.local/bin:$PATH"

COPY --from=download-toolchain /arm-none-eabi-toolchain /arm-none-eabi-toolchain
ENV PATH="/arm-none-eabi-toolchain/bin:$PATH"

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]
