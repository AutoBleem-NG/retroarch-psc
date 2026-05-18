# RetroArch ARM Cross-Compilation for PlayStation Classic
# Uses crosstool-ng to build a custom ARMv8 toolchain matching the original binary
#
# Build: make build (or: docker build -t retroarch-psc .)
# Extract: make extract
#
# Two-stage build:
#   Stage 1 (ctngbuild): Build custom GCC toolchain with crosstool-ng
#   Stage 2 (main): Compile RetroArch using the custom toolchain

# ==============================================================================
# Version Configuration
# ==============================================================================
ARG CROSSTOOL_NG_VERSION=1.28.0
ARG UPX_VERSION=5.0.2
ARG RETROARCH_VERSION=v1.22.2

# Toolchain versions - matched for PlayStation Classic compatibility
ARG CT_LINUX_VERSION=4_4
ARG CT_BINUTILS_VERSION=2_32
ARG CT_GLIBC_VERSION=2_23
ARG CT_GCC_VERSION=9

# User IDs for crosstool-ng build
ARG CTNG_UID=1000
ARG CTNG_GID=1000

# ==============================================================================
# Stage 1: Build Custom GCC Toolchain with crosstool-ng
# ==============================================================================
FROM ubuntu:16.04 AS ctngbuild

ARG CTNG_UID
ARG CTNG_GID
ARG CROSSTOOL_NG_VERSION
ARG CT_LINUX_VERSION
ARG CT_BINUTILS_VERSION
ARG CT_GLIBC_VERSION
ARG CT_GCC_VERSION

# Create user for crosstool-ng (cannot run as root)
RUN groupadd -g $CTNG_GID ctng && \
    useradd -d /home/ctng -m -g $CTNG_GID -u $CTNG_UID -s /bin/bash ctng

# Install crosstool-ng build dependencies
RUN apt-get update && \
    apt-get install -y \
        gcc g++ gperf bison flex texinfo help2man make libncurses5-dev \
        python3-dev autoconf automake libtool libtool-bin gawk wget bzip2 \
        xz-utils unzip patch libstdc++6 rsync meson ninja-build && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Setup crosstool-ng directories
RUN mkdir /opt/ctng && chmod 777 /opt/ctng && \
    mkdir /opt/x-tools && chmod 777 /opt/x-tools && \
    echo 'export PATH=/opt/ctng/bin:$PATH' >> /etc/profile

USER ctng

# Download and build crosstool-ng
RUN wget -O /tmp/crosstool.bz2 http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-${CROSSTOOL_NG_VERSION}.tar.bz2 && \
    cd /home/ctng && tar xvf /tmp/crosstool.bz2 && \
    rm /tmp/crosstool.bz2 && \
    cd /home/ctng/crosstool-ng-${CROSSTOOL_NG_VERSION} && \
    ./configure --prefix=/opt/ctng && \
    make && \
    make install

# Configure and build ARM toolchain for PlayStation Classic
# - ARMv8-A compatible (hard float, NEON)
# - Matches original RetroArch binary's toolchain
RUN echo 'CT_CONFIG_VERSION="4"' >> /tmp/defconfig && \
    echo 'CT_PREFIX_DIR="/opt/x-tools/${CT_HOST:+HOST-${CT_HOST}/}${CT_TARGET}"' >> /tmp/defconfig && \
    echo 'CT_ARCH_ARM=y' >> /tmp/defconfig && \
    echo 'CT_OMIT_TARGET_VENDOR=y' >> /tmp/defconfig && \
    echo 'CT_ARCH_FLOAT_HW=y' >> /tmp/defconfig && \
    echo 'CT_KERNEL_LINUX=y' >> /tmp/defconfig && \
    echo 'CT_LINUX_V_'${CT_LINUX_VERSION}'=y' >> /tmp/defconfig && \
    echo 'CT_BINUTILS_V_'${CT_BINUTILS_VERSION}'=y' >> /tmp/defconfig && \
    echo 'CT_GLIBC_V_'${CT_GLIBC_VERSION}'=y' >> /tmp/defconfig && \
    echo 'CT_GCC_V_'${CT_GCC_VERSION}'=y' >> /tmp/defconfig && \
    echo 'CT_CC_LANG_CXX=y' >> /tmp/defconfig && \
    echo 'CT_CC_GCC_LIBGOMP=y' >> /tmp/defconfig && \
    cd /tmp && /opt/ctng/bin/ct-ng defconfig && \
    echo 'CT_ZLIB_MIRRORS="http://downloads.sourceforge.net/project/libpng/zlib/${CT_ZLIB_VERSION} https://www.zlib.net/ https://www.zlib.net/fossils"' >> /tmp/.config && \
    cd /tmp && /opt/ctng/bin/ct-ng build

# ==============================================================================
# Stage 2: Build RetroArch
# ==============================================================================
FROM ubuntu:18.04

LABEL maintainer="AutoBleem-NG"
LABEL description="Docker build environment for RetroArch - PlayStation Classic (crosstool-ng)"

ARG UPX_VERSION
ARG RETROARCH_VERSION

ENV DEBIAN_FRONTEND=noninteractive

# ==============================================================================
# Install Build Dependencies
# ==============================================================================
RUN apt-get update && apt-get install -y \
    git \
    make \
    autoconf \
    pkg-config \
    pkg-config-arm-linux-gnueabihf \
    wget \
    curl \
    xz-utils \
    patchelf \
    && rm -rf /var/lib/apt/lists/*

# Download and install UPX for binary compression
RUN wget -q https://github.com/upx/upx/releases/download/v${UPX_VERSION}/upx-${UPX_VERSION}-amd64_linux.tar.xz && \
    tar -xf upx-${UPX_VERSION}-amd64_linux.tar.xz && \
    cp upx-${UPX_VERSION}-amd64_linux/upx /usr/local/bin/ && \
    chmod +x /usr/local/bin/upx && \
    rm -rf upx-${UPX_VERSION}-amd64_linux upx-${UPX_VERSION}-amd64_linux.tar.xz

# ==============================================================================
# Install ARM Libraries
# ==============================================================================
RUN dpkg --add-architecture armhf && \
    mv /etc/apt/sources.list /etc/apt/sources.list.bak && \
    echo "deb [arch=amd64] http://archive.ubuntu.com/ubuntu bionic main universe" > /etc/apt/sources.list && \
    echo "deb [arch=amd64] http://archive.ubuntu.com/ubuntu bionic-updates main universe" >> /etc/apt/sources.list && \
    echo "deb [arch=armhf] http://ports.ubuntu.com/ubuntu-ports bionic main universe" >> /etc/apt/sources.list && \
    echo "deb [arch=armhf] http://ports.ubuntu.com/ubuntu-ports bionic-updates main universe" >> /etc/apt/sources.list && \
    apt-get update && apt-get install -y \
    libasound2-dev:armhf \
    libudev-dev:armhf \
    libusb-1.0-0-dev:armhf \
    libsdl2-dev:armhf \
    libsdl2-dev \
    libgles2-mesa-dev:armhf \
    libegl1-mesa-dev:armhf \
    libdrm-dev:armhf \
    libgbm-dev:armhf \
    libfreetype6-dev:armhf \
    libfreetype6-dev \
    libwayland-dev:armhf \
    libxkbcommon-dev:armhf \
    libexpat1-dev:armhf \
    zlib1g-dev:armhf \
    && apt-get remove -y libpulse-dev:armhf || true \
    && rm -rf /var/lib/apt/lists/*

# ==============================================================================
# Copy Custom Toolchain from Stage 1
# ==============================================================================
RUN mkdir -p /opt/x-tools
COPY --from=ctngbuild /opt/x-tools/arm-linux-gnueabihf /opt/x-tools/arm-linux-gnueabihf

# ==============================================================================
# Environment Setup for Cross-Compilation
# ==============================================================================
ENV PATH="/opt/x-tools/arm-linux-gnueabihf/bin:${PATH}"
ENV CC=arm-linux-gnueabihf-gcc
ENV CXX=arm-linux-gnueabihf-g++
ENV AR=arm-linux-gnueabihf-ar
ENV PKG_CONFIG_PATH=/usr/lib/arm-linux-gnueabihf/pkgconfig
ENV PKG_CONFIG_LIBDIR=/usr/lib/arm-linux-gnueabihf/pkgconfig
ENV PKG_CONFIG=/usr/bin/arm-linux-gnueabihf-pkg-config
ENV LDFLAGS="-L/opt/x-tools/arm-linux-gnueabihf/arm-linux-gnueabihf/sysroot/usr/lib -Wl,-rpath-link,/opt/x-tools/arm-linux-gnueabihf/arm-linux-gnueabihf/sysroot/lib -L/usr/lib/arm-linux-gnueabihf -Wl,-rpath-link,/usr/lib/arm-linux-gnueabihf"
ENV LIBRARY_PATH=/opt/x-tools/arm-linux-gnueabihf/arm-linux-gnueabihf/sysroot/usr/lib:/opt/x-tools/arm-linux-gnueabihf/arm-linux-gnueabihf/sysroot/lib:/usr/lib/arm-linux-gnueabihf

# Create dummy immintrin.h for SDL2 (SDL 2.0.8 has x86 intrinsics includes without ARM guards)
RUN mkdir -p /opt/arm-compat-headers && \
    echo '/* Dummy immintrin.h for ARM cross-compilation */' > /opt/arm-compat-headers/immintrin.h

# Create wrapper scripts that point crosstool-ng compiler to Ubuntu's ARM libraries
# Note: SDL2 headers go in /usr/include/SDL2/ (arch-independent) not armhf-specific path
RUN echo '#!/bin/bash' > /usr/bin/psc-gcc && \
    echo 'exec /opt/x-tools/arm-linux-gnueabihf/bin/arm-linux-gnueabihf-gcc -I/opt/arm-compat-headers -I/usr/include/SDL2 -idirafter /usr/include -idirafter /usr/include/arm-linux-gnueabihf -L/opt/x-tools/arm-linux-gnueabihf/arm-linux-gnueabihf/sysroot/usr/lib -L/usr/lib/arm-linux-gnueabihf "$@"' >> /usr/bin/psc-gcc && \
    chmod +x /usr/bin/psc-gcc && \
    echo '#!/bin/bash' > /usr/bin/psc-g++ && \
    echo 'exec /opt/x-tools/arm-linux-gnueabihf/bin/arm-linux-gnueabihf-g++ -I/opt/arm-compat-headers -I/usr/include/SDL2 -idirafter /usr/include -idirafter /usr/include/arm-linux-gnueabihf -L/opt/x-tools/arm-linux-gnueabihf/arm-linux-gnueabihf/sysroot/usr/lib -L/usr/lib/arm-linux-gnueabihf "$@"' >> /usr/bin/psc-g++ && \
    chmod +x /usr/bin/psc-g++

# Fix ARM library symlinks and pkg-config files
# Dev packages only install versioned .so files, not the unversioned symlinks needed for linking
RUN ln -sf libSDL2-2.0.so.0 /usr/lib/arm-linux-gnueabihf/libSDL2.so && \
    ln -sf libEGL.so.1 /usr/lib/arm-linux-gnueabihf/libEGL.so && \
    ln -sf libGLESv2.so.2 /usr/lib/arm-linux-gnueabihf/libGLESv2.so && \
    ln -sf libdrm.so.2 /usr/lib/arm-linux-gnueabihf/libdrm.so && \
    ln -sf libgbm.so.1 /usr/lib/arm-linux-gnueabihf/libgbm.so && \
    # SDL2 pkg-config (armhf headers in arch-specific include dir)
    echo 'prefix=/usr' > /usr/lib/arm-linux-gnueabihf/pkgconfig/sdl2.pc && \
    echo 'exec_prefix=${prefix}' >> /usr/lib/arm-linux-gnueabihf/pkgconfig/sdl2.pc && \
    echo 'libdir=${exec_prefix}/lib/arm-linux-gnueabihf' >> /usr/lib/arm-linux-gnueabihf/pkgconfig/sdl2.pc && \
    echo 'includedir=${prefix}/include/arm-linux-gnueabihf' >> /usr/lib/arm-linux-gnueabihf/pkgconfig/sdl2.pc && \
    echo 'Name: sdl2' >> /usr/lib/arm-linux-gnueabihf/pkgconfig/sdl2.pc && \
    echo 'Description: Simple DirectMedia Layer' >> /usr/lib/arm-linux-gnueabihf/pkgconfig/sdl2.pc && \
    echo 'Version: 2.0.8' >> /usr/lib/arm-linux-gnueabihf/pkgconfig/sdl2.pc && \
    echo 'Libs: -L${libdir} -lSDL2' >> /usr/lib/arm-linux-gnueabihf/pkgconfig/sdl2.pc && \
    echo 'Cflags: -I${includedir}/SDL2 -D_REENTRANT' >> /usr/lib/arm-linux-gnueabihf/pkgconfig/sdl2.pc && \
    # EGL pkg-config
    echo 'prefix=/usr' > /usr/lib/arm-linux-gnueabihf/pkgconfig/egl.pc && \
    echo 'libdir=${prefix}/lib/arm-linux-gnueabihf' >> /usr/lib/arm-linux-gnueabihf/pkgconfig/egl.pc && \
    echo 'includedir=${prefix}/include' >> /usr/lib/arm-linux-gnueabihf/pkgconfig/egl.pc && \
    echo 'Name: egl' >> /usr/lib/arm-linux-gnueabihf/pkgconfig/egl.pc && \
    echo 'Description: EGL library' >> /usr/lib/arm-linux-gnueabihf/pkgconfig/egl.pc && \
    echo 'Version: 1.4' >> /usr/lib/arm-linux-gnueabihf/pkgconfig/egl.pc && \
    echo 'Libs: -L${libdir} -lEGL' >> /usr/lib/arm-linux-gnueabihf/pkgconfig/egl.pc && \
    echo 'Cflags: -I${includedir}' >> /usr/lib/arm-linux-gnueabihf/pkgconfig/egl.pc && \
    # GLESv2 pkg-config
    echo 'prefix=/usr' > /usr/lib/arm-linux-gnueabihf/pkgconfig/glesv2.pc && \
    echo 'libdir=${prefix}/lib/arm-linux-gnueabihf' >> /usr/lib/arm-linux-gnueabihf/pkgconfig/glesv2.pc && \
    echo 'includedir=${prefix}/include' >> /usr/lib/arm-linux-gnueabihf/pkgconfig/glesv2.pc && \
    echo 'Name: glesv2' >> /usr/lib/arm-linux-gnueabihf/pkgconfig/glesv2.pc && \
    echo 'Description: OpenGL ES 2.0 library' >> /usr/lib/arm-linux-gnueabihf/pkgconfig/glesv2.pc && \
    echo 'Version: 2.0' >> /usr/lib/arm-linux-gnueabihf/pkgconfig/glesv2.pc && \
    echo 'Libs: -L${libdir} -lGLESv2' >> /usr/lib/arm-linux-gnueabihf/pkgconfig/glesv2.pc && \
    echo 'Cflags: -I${includedir}' >> /usr/lib/arm-linux-gnueabihf/pkgconfig/glesv2.pc

# ==============================================================================
# Build RetroArch
# ==============================================================================
WORKDIR /build

# Clone RetroArch with retry
RUN git config --global http.postBuffer 524288000 && \
    git config --global http.lowSpeedLimit 1000 && \
    git config --global http.lowSpeedTime 300 && \
    (git clone --depth=1 --branch ${RETROARCH_VERSION} https://github.com/libretro/RetroArch.git || \
     (sleep 10 && git clone --depth=1 --branch ${RETROARCH_VERSION} https://github.com/libretro/RetroArch.git) || \
     (sleep 30 && git clone --depth=1 --branch ${RETROARCH_VERSION} https://github.com/libretro/RetroArch.git))

WORKDIR /build/RetroArch
RUN git submodule update --init --recursive --depth 1

# Restore wl_shell fallback for PSC's Weston 1.11 (only supports wl_shell,
# not xdg_shell). Upstream removed wl_shell in 8345f08 (RA 1.7.9).
COPY patches/wl_shell_fallback.patch /build/RetroArch/patches/wl_shell_fallback.patch
RUN git apply /build/RetroArch/patches/wl_shell_fallback.patch

# Skip the OES_standard_derivatives extension request when the runtime
# promotes the XMB ribbon shader to "#version 300 es" — PowerVR Rogue
# rejects the now-meaningless extension and refuses to compile the shader.
COPY patches/xmb_ribbon_drop_oes_derivatives_ext.patch /build/RetroArch/patches/xmb_ribbon_drop_oes_derivatives_ext.patch
RUN git apply /build/RetroArch/patches/xmb_ribbon_drop_oes_derivatives_ext.patch

# Force S16_LE for ALSA: the PSC's MT8167 driver falsely reports FLOAT as
# supported via test_format, then rejects it with EINVAL in snd_pcm_hw_params.
# RA has no retry path, so audio init fails entirely without this patch.
COPY patches/alsa_force_s16_psc_mtk.patch /build/RetroArch/patches/alsa_force_s16_psc_mtk.patch
RUN git apply /build/RetroArch/patches/alsa_force_s16_psc_mtk.patch

# Copy PSC-specific Makefile
COPY Makefile.psc /build/RetroArch/Makefile.psc

# Build using PSC makefile with crosstool-ng compiler
RUN CC=psc-gcc CXX=psc-g++ make -f Makefile.psc -j$(nproc)

# Show binary info
RUN ls -lh retroarch && \
    file retroarch && \
    arm-linux-gnueabihf-readelf -A retroarch | head -20

# Copy to output directory
RUN mkdir -p /build/output && cp retroarch /build/output/

CMD ["/bin/bash"]
