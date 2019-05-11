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
RUN cargo install xargo

# Update devkitA64
RUN dkp-pacman --noconfirm -Syyu

# Add target
COPY aarch64-horizon-elf.json /etc/rust-targets/
ENV RUST_TARGET_PATH=/etc/rust-targets/

# Build sysroot
COPY sysroot-builder/ /tmp/sysroot-builder/
RUN cd /tmp/sysroot-builder/ && \
    xargo build --target aarch64-horizon-elf && \
    cd / && \
    rm -rf /tmp/sysroot-builder/

# Mount the work directory
WORKDIR workdir
VOLUME workdir
