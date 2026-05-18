# RetroArch for PlayStation Classic

Docker-based cross-compile of [RetroArch](https://github.com/libretro/RetroArch) for the PlayStation Classic, producing binaries compatible with [AutoBleem-NG](https://github.com/AutoBleem-NG).

## Build

```bash
make
ls retroarch_bin/retroarch
```

See [docs/building.md](docs/building.md) for toolchain details and release packaging.

## Runtime Configuration

This binary is **not** a drop-in replacement for older PSC RetroArch builds. RetroArch 1.22+ needs:

```ini
video_driver = "gl"
video_context_driver = "wayland"
menu_driver = "ozone"
```

XMB does not work — the Mali-T720 cannot compile the updated ribbon shader. Use Ozone or RGUI.

Full driver/menu matrix and troubleshooting: [docs/psc-configuration.md](docs/psc-configuration.md).

## Patches

`patches/wl_shell_fallback.patch` restores the legacy `wl_shell` code path that upstream removed in RA 1.7.9. PSC's Weston 1.11 only advertises `wl_shell`, not `xdg_shell`, so without the patch the native Wayland context fails at startup with `[Wayland] Failed to create shell.`

## Target

ARMv8-A Cortex-A35 · crosstool-ng GCC 9 · glibc 2.23 · all 18 runtime dependencies satisfied by stock PSC firmware.

## License

GPL-3.0 — based on [retroarch-cross-compile](https://github.com/zoltanvb/retroarch-cross-compile) by Zoltan Baldaszti.
