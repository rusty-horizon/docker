FROM gcc:7 AS builder

# Add backport repos
RUN printf "deb http://httpredir.debian.org/debian stretch-backports main non-free\ndeb-src http://httpredir.debian.org/debian stretch-backports main non-free" > /etc/apt/sources.list.d/backports.list

# Install git and up-to-date cmake
RUN apt-get update && apt-get install -y git && apt-get -t stretch-backports install -y cmake

# Clone twili
RUN git clone --recursive --depth=1 --single-branch https://github.com/misson20000/twili.git /root/twili

# Build twili
RUN cd /root/twili/twib && mkdir build && cd build && mkdir prefix && \
    cmake -G "Unix Makefiles" .. -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_INSTALL_PREFIX=/root/twili/twib/build/prefix \
          -DTWIBD_LIBUSB_BACKEND_ENABLED=OFF && \
    make -j4 && make install

FROM devkitpro/devkita64
ENV PATH=$DEVKITPRO/devkitA64/bin:$PATH

# Install GCC for the CC link
RUN sudo apt-get update
RUN sudo apt-get install -y build-essential

# Install Rust
RUN curl https://sh.rustup.rs -sSf > rust-init.rs
RUN chmod +x rust-init.rs
RUN ./rust-init.rs -y --default-toolchain nightly-2019-01-19
RUN rm rust-init.rs
ENV PATH=/root/.cargo/bin:$PATH
RUN rustup component add rust-src

# Install dependencies
RUN cargo install xargo
RUN cargo install --git https://github.com/MegatonHammer/linkle.git --all-features
RUN cargo install --git https://github.com/rusty-horizon/aarch64-horizon-nro-ld.git

# Update devkitA64
RUN dkp-pacman --noconfirm -Syyu

# Add targets
COPY aarch64-horizon-elf.json /etc/rust-targets/
COPY aarch64-horizon-nro.json /etc/rust-targets/
ENV RUST_TARGET_PATH=/etc/rust-targets/

# Build sysroot
COPY sysroot-builder/ /tmp/sysroot-builder/

# aarch64-horizon-elf
RUN cd /tmp/sysroot-builder/ && \
    xargo build --target aarch64-horizon-elf -vv

# aarch64-horizon-nro
RUN cd /tmp/sysroot-builder/ && \
    xargo build --target aarch64-horizon-nro -vv

# Cleanup
RUN rm -rf /tmp/sysroot-builder/

# Copy twib
COPY --from=builder /root/twili/twib/build/prefix/bin/twib /usr/bin/twib

# Add cargo config
COPY cargo-config.toml /.cargo/config

# Mount the work directory
WORKDIR workdir
VOLUME workdir
