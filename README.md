# Taylor's `zig-snes` Test
It would be nice to get this working without needing Docker. You just need to install `zig-mos` in order to build for 6502-based targets.

This was the contents of the Dockerfile in the original `zig-snes`:
```dockerfile
FROM debian:bookworm

ENV PATH="$PATH:/zig:/llvm-mos/bin"

# Install packages.
RUN apt-get update && apt-get install -y \
    wget \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Install zig-mos.
RUN wget https://github.com/kassane/zig-mos-bootstrap/releases/download/0.1/zig-mos-x86_64-linux-musl-baseline.tar.xz \
    && tar -xf zig-mos-x86_64-linux-musl-baseline.tar.xz \
    && mv zig-mos-x86_64-linux-musl-baseline zig \
    && rm zig-mos-x86_64-linux-musl-baseline.tar.xz

# Install llvm-mos.
RUN wget https://github.com/llvm-mos/llvm-mos-sdk/releases/latest/download/llvm-mos-linux.tar.xz \
    && tar -xf llvm-mos-linux.tar.xz \
    && rm llvm-mos-linux.tar.xz
```
