# RetroArch Configuration for PlayStation Classic

## Hardware

- **SoC**: MediaTek MT8167 (ARM Cortex-A35 quad-core)
- **GPU**: PowerVR Rogue GE8300 (OpenGL ES 3.2)
- **Kernel**: Linux 4.4.22, glibc 2.24
- **Display**: Weston 1.11 (Wayland, `wl_shell` only — no `xdg_shell`)

The MT8167 family is commonly documented as shipping with Mali-T720, but PSC units actually report PowerVR Rogue GE8300. PowerVR's GLSL compiler is stricter about extensions — relevant for [`xmb_ribbon_drop_oes_derivatives_ext.patch`](../patches/xmb_ribbon_drop_oes_derivatives_ext.patch).

## Working Configuration

```ini
video_driver = "gl"
video_context_driver = "wayland"
menu_driver = "xmb"   # or "ozone" / "rgui"
```

`gl_sdl` works as a fallback context (GL via SDL2/Wayland) but adds indirection. Don't leave `video_context_driver` unset — RA will try KMS first, which Weston blocks.

| video_driver | context  | menu drivers     | status |
|--------------|----------|------------------|--------|
| `gl`         | `wayland`| XMB, Ozone, RGUI | ✅ recommended |
| `gl`         | `gl_sdl` | XMB, Ozone, RGUI | ✅ fallback |
| `gl`         | `kms`    | —                | ❌ conflicts with Weston |
| `sdl2`       | —        | RGUI only        | ✅ |

## Patches (applied at build time)

- **`wl_shell_fallback.patch`** — restores the legacy `wl_shell` code path (removed upstream in `8345f08`, RA 1.7.9). Without it: `[ERROR] [Wayland] Failed to create shell.` With it: `[WARN] [Wayland] xdg_shell unavailable; falling back to deprecated wl_shell.`

- **`xmb_ribbon_drop_oes_derivatives_ext.patch`** — guards `#extension GL_OES_standard_derivatives : enable` with `#if __VERSION__ < 300`. The XMB ribbon fragment shader is wrapped in a `#version 130` placeholder that `shader_glsl.c:381` promotes to `#version 300 es` on GLES3 hardware. Derivatives are core in ES 3.0+, but PowerVR Rogue hard-errors on the now-redundant extension request with `[GLSL] Shader log: Compile failed.` → `[GL] GL: Invalid value` → `Cannot open video driver`.

## libstdc++

PSC firmware ships `libstdc++.so.6.0.22` with `GLIBCXX_3.4.22`. Older RetroBoot installs that bundle a stale `libstdc++.so.6` should be replaced with `/usr/lib/libstdc++.so.6.0.22` from the PSC.

## Input

`input_driver` must match the autoconfig files. PSC's `PlayStation_Classic_Controller.cfg` uses `udev`:

```ini
input_driver = "udev"
input_autodetect_enable = true
joypad_autoconfig_dir = "/media/retroarch/autoconfig"
```

## Troubleshooting

Log: `/media/retroarch/logs/retroarch.log` (enable via `log_verbosity = "true"` and `log_to_file = "true"`).

| Symptom | Likely cause |
|---------|--------------|
| Exits immediately at startup | Video driver init — check the log for shader/EGL errors |
| Black screen with audio | `video_context_driver` unset → tried KMS; set it to `wayland` |
| Menu falls back to RGUI | Configured menu driver failed (missing assets or shader compile error) |
| Controller dead | `input_driver` doesn't match the autoconfig file (use `udev`) |
