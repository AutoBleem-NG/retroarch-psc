# RetroArch for PlayStation Classic

Build system for RetroArch on PlayStation Classic, producing binaries compatible with [AutoBleem-NG](https://github.com/AutoBleem-NG).

## Important: Configuration Required

**You cannot simply replace an older RetroArch binary with this one.** RetroArch 1.22+ requires specific configuration changes:

```ini
video_driver = "gl"
video_context_driver = "gl_sdl"
menu_driver = "ozone"
```

### XMB Menu Not Supported in 1.22+

The XMB menu **does not work** with this build. The Mali-T720 GPU cannot compile XMB's updated ribbon shader:

```
[ERROR] [GLSL] Failed to compile fragment shader #62.
```

Use **Ozone** or **RGUI** instead. See [PSC Configuration Guide](docs/psc-configuration.md) for details.

## Quick Start

```bash
make              # Build and extract binary
ls retroarch_bin/retroarch
```

## Documentation

- [Building](docs/building.md) - Build instructions, toolchain details, configuration
- [PSC Configuration](docs/psc-configuration.md) - Runtime configuration, drivers, troubleshooting

## Compatibility

- **Target**: ARMv8-A Cortex-A35 (PSC SoC)
- **Toolchain**: crosstool-ng GCC 9, glibc 2.23
- **Dependencies**: All 18 shared libraries present on stock PSC firmware

## License

GPL-3.0 - Based on [retroarch-cross-compile](https://github.com/zoltanvb/retroarch-cross-compile) by Zoltan Baldaszti.
