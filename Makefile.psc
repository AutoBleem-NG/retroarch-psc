# RetroArch build for PlayStation Classic (Cortex-A35, AArch32, glibc 2.23).
# Based on libretro's Makefile.classic_snesc. Flags align with AutoBleem
# CMakeLists.txt @ 6e341aeb.
#
# Gotchas (do not "fix" without re-reading these):
#
# - HAVE_C_A7A7 is for Cortex-A7 (NES/SNES Classic) and would override our
#   Cortex-A35 flags. HAVE_CLASSIC=1 is a harmless no-op in v1.22.2.
#
# - --enable-floathard is a CPU FP-ABI flag and does not affect ALSA format
#   selection. The actual audio fix is patches/alsa_force_s16_psc_mtk.patch:
#   the MT8167 driver falsely reports FLOAT support in test_format, then
#   rejects it with EINVAL in snd_pcm_hw_params; the patch forces S16_LE.
#
# - -mfpu=neon-vfpv4, NOT neon-fp-armv8: PSC kernel HWCAP advertises only
#   VFPV3/VFPV4 even though the silicon is ARMv8. neon-fp-armv8 emits
#   instructions for an FPU the runtime denies having.
#
# - RetroArch's --enable-neon injects a late NEON_CFLAGS=-mfpu=neon, which
#   overrides the earlier PSC FPU flag. Keep NEON_CFLAGS/NEON_ASFLAGS aligned
#   with the PSC target when invoking make.

TARGET := retroarch

all: $(TARGET)

retroarch:
	export PKG_CONFIG_PATH=/usr/lib/arm-linux-gnueabihf/pkgconfig && \
	export PKG_CONFIG_LIBDIR=/usr/lib/arm-linux-gnueabihf/pkgconfig && \
	export SDL2_CFLAGS="-I/usr/include/arm-linux-gnueabihf/SDL2 -D_REENTRANT" && \
	export SDL2_LIBS="-L/usr/lib/arm-linux-gnueabihf -lSDL2" && \
	export CFLAGS="-march=armv8-a -mtune=cortex-a35 -mfpu=neon-vfpv4 -mfloat-abi=hard \
		-O3 -fno-pie -fomit-frame-pointer -ffunction-sections -fdata-sections \
		-funroll-loops -ftree-vectorize \
		-fno-math-errno -fno-trapping-math -fno-signed-zeros -fprefetch-loop-arrays \
		-I/usr/include/arm-linux-gnueabihf -I/usr/include/arm-linux-gnueabihf/SDL2" && \
	export CXXFLAGS="-march=armv8-a -mtune=cortex-a35 -mfpu=neon-vfpv4 -mfloat-abi=hard \
		-O3 -fno-pie -fomit-frame-pointer -ffunction-sections -fdata-sections \
		-funroll-loops -ftree-vectorize \
		-fno-math-errno -fno-trapping-math -fno-signed-zeros -fprefetch-loop-arrays \
		-I/usr/include/arm-linux-gnueabihf -I/usr/include/arm-linux-gnueabihf/SDL2" && \
	export LDFLAGS="-L/opt/x-tools/arm-linux-gnueabihf/arm-linux-gnueabihf/sysroot/usr/lib \
		-Wl,-rpath-link,/opt/x-tools/arm-linux-gnueabihf/arm-linux-gnueabihf/sysroot/lib \
		-L/usr/lib/arm-linux-gnueabihf -Wl,-rpath-link,/usr/lib/arm-linux-gnueabihf \
		-no-pie -Wl,--gc-sections -Wl,--as-needed -Wl,--allow-shlib-undefined \
		-static-libstdc++ -static-libgcc" && \
	./configure \
		--host=arm-linux-gnueabihf \
		--disable-pulse \
		--enable-wayland \
		--disable-x11 \
		--disable-opengl \
		--disable-opengl1 \
		--disable-opengl_core \
		--enable-opengles \
		--enable-egl \
		--enable-freetype \
		--enable-udev \
		--enable-alsa \
		--enable-neon \
		--enable-sdl2 \
		--disable-discord && \
	make HAVE_CLASSIC=1 \
		GIT_VERSION="autobleem-ng-$(PSC_BUILD_NUM)" \
		NEON_CFLAGS="-mfpu=neon-vfpv4" \
		NEON_ASFLAGS="-mfpu=neon-vfpv4" \
		-j && \
	/opt/x-tools/arm-linux-gnueabihf/bin/arm-linux-gnueabihf-strip -v retroarch

clean:
	rm -rf obj-unix
	rm -f *.d *.o
	rm -f audio/*.o conf/*.o gfx/*.o input/*.o
	rm -f gfx/drivers_font/*.o gfx/drivers_font_renderer/*.o gfx/drivers_context/*.o
	rm -f compat/*.o record/*.o tools/*.o
	rm -f retroarch
