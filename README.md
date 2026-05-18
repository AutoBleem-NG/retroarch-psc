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
menu_driver = "xmb"   # or "ozone" / "rgui"
```

Full driver/menu matrix and troubleshooting: [docs/psc-configuration.md](docs/psc-configuration.md).

## Patches

- `alsa_force_s16_psc_mtk.patch` — forces ALSA S16_LE on PSC's MT8167 (which mis-advertises FLOAT support).
- `wl_shell_fallback.patch` — Wayland fallback for PSC's Weston 1.11 (no `xdg_shell`).
- `xmb_ribbon_drop_oes_derivatives_ext.patch` — fixes the XMB ribbon shader on PowerVR Rogue.

See [docs/psc-configuration.md](docs/psc-configuration.md) for the why.

## Target

ARMv8-A Cortex-A35 · crosstool-ng GCC 9 · glibc 2.23 · all 18 runtime dependencies satisfied by stock PSC firmware.

## License

GPL-3.0 — based on [retroarch-cross-compile](https://github.com/zoltanvb/retroarch-cross-compile) by Zoltan Baldaszti.
