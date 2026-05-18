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
| `make package` | Extract and zip for release |
| `make release` | Build + package (full release) |
| `make version` | Show version info |
| `make shell` | Interactive container shell |
| `make clean` | Remove binary and image |

## Versioning

Releases use combined versioning: `{RetroArch version}-{build number}`

Example: `retroarch-psc-v1.22.2-1.zip`

- RetroArch version comes from `RETROARCH_VERSION` in Dockerfile
- Build number comes from git tag suffix

### Git Tag Format

Tags must follow: `v{RA_VERSION}-{BUILD_NUM}`

```
v1.22.2-1    # First release of RetroArch v1.22.2
v1.22.2-2    # Second release (e.g., build config fix)
v1.23.0-1    # First release of RetroArch v1.23.0
```

### Creating a Release

```bash
# Tag the release
git tag v1.22.2-1

# Build and package
make release

# Output: retroarch_bin/retroarch-psc-v1.22.2-1.zip
```

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
- **FPU**: NEON + VFPV4, hard-float ABI

### Compiler Flags

```
-march=armv8-a -mtune=cortex-a35 -mfpu=neon-vfpv4 -mfloat-abi=hard
-O3 -funroll-loops -ftree-vectorize -ffunction-sections -fdata-sections
```

`-mfpu=neon-vfpv4` (not `neon-fp-armv8`) is intentional: the PSC kernel's HWCAP advertises only VFPV3/VFPV4 even though the silicon is ARMv8, so emitting ARMv8 FPU instructions traps at runtime.

## Build Features

Enabled:
- SDL2 (input/joystick)
- Wayland (native context, with `wl_shell` fallback for PSC's Weston 1.11)
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
