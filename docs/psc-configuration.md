# RetroArch Configuration for PlayStation Classic

Runtime configuration reference for RetroArch on PSC hardware.

## PSC Hardware Specifications

- **SoC**: MediaTek MT8167A (ARM Cortex-A35 quad-core)
- **GPU**: Mali-T720 MP2 (OpenGL ES 3.1)
- **Kernel**: Linux 4.4.22
- **Display Server**: Weston (Wayland compositor)
- **glibc**: 2.24 (GCC 6.2.0)

## Working Configuration

The following configuration works with RetroArch 1.22+ on PSC:

```ini
video_driver = "gl"
video_context_driver = "wayland"
audio_driver = "alsa"
input_driver = "udev"
menu_driver = "ozone"
```

`gl_sdl` is also supported as a fallback (creates the GL context through SDL2's Wayland backend) but adds a layer of indirection. Prefer the native `wayland` context.

### Video Driver Options

| Driver | Context | Menu Support | Status |
|--------|---------|--------------|--------|
| `sdl2` | N/A | RGUI only | Works |
| `gl` | `wayland` | Ozone, RGUI | Works (native, recommended) |
| `gl` | `gl_sdl` | Ozone, RGUI | Works (via SDL2) |
| `gl` | `kms` | - | Fails (mode switching) |

### Menu Driver Compatibility

| Menu | Video Driver | Status | Notes |
|------|--------------|--------|-------|
| RGUI | `sdl2` | Works | Basic menu, no icons |
| RGUI | `gl` + `wayland` | Works | Basic menu |
| Ozone | `gl` + `wayland` | Works | Modern menu with icons |
| XMB | `gl` + `wayland` | Fails | Shader compilation error |

## Known Issues

### XMB Menu Shader Failure (1.22+)

XMB requires advanced GLSL shaders that the Mali-T720 GPU cannot compile in RetroArch 1.22+:

```
[ERROR] [GLSL] Failed to compile fragment shader #62.
[ERROR] [GLSL] Failed to link program #62.
```

The failing shader is the "ribbon" effect which uses GLSL features unsupported by the Mali GPU's OpenGL ES implementation.

**Workaround**: Use Ozone menu instead of XMB.

### Wayland Shell Creation (resolved by patch)

Upstream RetroArch ≥ 1.7.9 only supports the modern `xdg_shell` protocol. PSC's Weston 1.11 ships the legacy `wl_shell` protocol only, so a stock build fails at startup with:

```
[ERROR] [Wayland] Failed to create shell.
```

This build applies `patches/wl_shell_fallback.patch`, which restores the `wl_shell` code path that upstream removed in commit `8345f08`. When `xdg_shell` is absent, RetroArch now binds `wl_shell` and emits:

```
[WARN] [Wayland] xdg_shell unavailable; falling back to deprecated wl_shell.
```

No runtime configuration is required — the native `wayland` context works on PSC out of the box with this build.

### KMS Mode Switching Failure

When Wayland fails, RetroArch falls back to KMS/DRM which also fails:

```
[INFO] [KMS] New FB: 1920x1080 (stride: 7680).
[ERROR] [KMS] Error when switching mode.
```

The PSC's display is managed by Weston, so direct KMS access conflicts with it.

**Solution**: Use SDL2 context instead of direct KMS.

## Library Requirements

All required libraries are present on stock PSC firmware. RetroArch dynamically links against 18 libraries:

| Library | Purpose | PSC Version |
|---------|---------|-------------|
| libasound.so.2 | ALSA audio | 2.0.0 |
| libfreetype.so.6 | Font rendering | 6.12.5 |
| libwayland-egl.so.1 | Wayland EGL | 1.0.0 |
| libwayland-client.so.0 | Wayland client | 0.3.0 |
| libwayland-cursor.so.0 | Wayland cursor | 0.0.0 |
| libxkbcommon.so.0 | Keyboard handling | 0.0.0 |
| libSDL2-2.0.so.0 | Input/joystick | 0.4.0 |
| libGLESv2.so.2 | OpenGL ES 2.0 | 2.0.0 |
| libEGL.so.1 | EGL | 1.0.0 |
| libgbm.so.1 | Generic buffer mgmt | 1.0.0 |
| libdrm.so.2 | Direct rendering | 2.4.0 |
| libudev.so.1 | Device hotplug | 1.6.4 |
| libstdc++.so.6 | C++ standard library | 6.0.22 |
| libc.so.6 | C library | 2.24 |
| libm.so.6 | Math library | 2.24 |
| libpthread.so.0 | Threading | 2.24 |
| librt.so.1 | Realtime extensions | 2.24 |
| libdl.so.2 | Dynamic linking | 2.24 |

### libstdc++ Note

PSC firmware includes `libstdc++.so.6.0.22` with `GLIBCXX_3.4.22`. If using older RetroBoot installations that bundle an older libstdc++, replace it with PSC's native version from `/usr/lib/libstdc++.so.6.0.22`.

## Input Configuration

### Controller Autoconfig

The `input_driver` must match the autoconfig files. PSC controller autoconfig files use `udev`:

```ini
input_driver = "udev"
input_autodetect_enable = true
joypad_autoconfig_dir = "/media/retroarch/autoconfig"
```

The stock PSC controller config is `PlayStation_Classic_Controller.cfg`.

## Directory Structure

```
/media/retroarch/
├── retroarch              # Main binary
├── retroarch.cfg          # Main configuration
├── assets/                # Menu assets (icons, fonts)
│   ├── ozone/
│   ├── xmb/
│   └── glui/
├── cores/                 # Libretro cores (.so files)
├── info/                  # Core info files
├── autoconfig/            # Controller autoconfig
├── retroboot/
│   ├── lib/               # Additional libraries
│   │   ├── libstdc++.so.6
│   │   └── liblzma.so.5
│   └── bin/               # Launch scripts
└── system/                # BIOS files
```

## Updating Assets

Assets should match the RetroArch version. Download from:
https://github.com/libretro/retroarch-assets

Required directories:
- `ozone/` - Ozone theme assets (recommended)
- `glui/` - GLUI/MaterialUI assets
- `sounds/` - Menu sounds
- `fonts/` - Font files

## Troubleshooting

### RetroArch Exits Immediately

Check `/media/retroarch/logs/retroarch.log` for errors.

Common causes:
1. Video driver initialization failure
2. Missing libraries (check GLIBCXX version)
3. Missing assets for menu driver

### Black Screen with Audio

Video context mismatch. With `video_driver = "gl"`, set `video_context_driver = "wayland"` (or `gl_sdl` as a fallback). Leaving the context unset lets RetroArch try `kms` first, which fails on PSC.

### Controller Not Working

Verify `input_driver` matches autoconfig files. Use `udev` for PSC controllers.

### Menu Falls Back to RGUI

The configured menu driver failed to initialize (usually due to missing assets or shader compilation failure). Check logs for specific error.

## References

- [RetroArch Documentation](https://docs.libretro.com/)
- [PSC Specifications](https://en.wikipedia.org/wiki/PlayStation_Classic)
- [Mali-T720 OpenGL ES Support](https://developer.arm.com/ip-products/graphics-and-multimedia/mali-gpus/mali-t720-gpu)
