# Building RetroArch for PSC

Docker-based cross-compilation for RetroArch on PlayStation Classic.

## Requirements

- Docker

## Quick Start

```bash
make              # Build and extract binary
ls retroarch_bin/retroarch
```

## Make Targets

| Target | Description |
|--------|-------------|
| `make` | Build and extract binary |
| `make build` | Build Docker image only |
| `make extract` | Extract binary from image |
| `make shell` | Interactive container shell |
| `make clean` | Remove binary and image |

## Configuration

Edit Dockerfile ARGs to customize the build:

| ARG | Default | Description |
|-----|---------|-------------|
| `RETROARCH_VERSION` | v1.22.2 | RetroArch git tag |
| `CROSSTOOL_NG_VERSION` | 1.28.0 | Toolchain builder version |
| `CT_GCC_VERSION` | 9 | GCC version |
| `CT_GLIBC_VERSION` | 2_23 | glibc version |

### Build Specific Version

```bash
docker build --build-arg RETROARCH_VERSION=v1.19.1 -t retroarch-psc .
make extract
```

## Toolchain

Two-stage Docker build:

1. **Stage 1** (Ubuntu 16.04): Build crosstool-ng ARM toolchain
   - GCC 9, glibc 2.23, kernel headers 4.4

2. **Stage 2** (Ubuntu 18.04): Compile RetroArch
   - Uses custom toolchain from stage 1
   - Links against Ubuntu armhf libraries

### Target Architecture

- **CPU**: ARMv8-A Cortex-A35 (PSC SoC)
- **FPU**: NEON-FP-ARMv8, hard-float ABI

### Compiler Flags

```
-march=armv8-a -mtune=cortex-a35 -mfpu=neon-fp-armv8 -mfloat-abi=hard
-O3 -funroll-loops -ftree-vectorize -ffunction-sections -fdata-sections
```

## Build Features

Enabled:
- SDL2 (input/joystick)
- Wayland (display via SDL2 context)
- OpenGL ES + EGL
- Freetype (fonts)
- ALSA (audio)
- udev (device hotplug)
- NEON SIMD

Disabled:
- PulseAudio
- X11
- Desktop OpenGL
- Discord integration

## Debugging

```bash
make shell
# Inside container:
cd /build/RetroArch
make -f Makefile.psc clean
CC=psc-gcc CXX=psc-g++ make -f Makefile.psc -j$(nproc)
```

## Output

The build produces a stripped ARM binary at `retroarch_bin/retroarch`.

All 18 shared library dependencies are satisfied by stock PSC firmware - no additional libraries need to be bundled.
