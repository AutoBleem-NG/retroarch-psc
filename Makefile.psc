# RetroArch Build for PlayStation Classic
# Based on Makefile.classic_snesc from libretro/RetroArch
# Modified by AutoBleem-NG for PSC-specific optimizations
#
# Note: HAVE_C_A7A7 is intentionally NOT used — it targets Cortex-A7/ARMv7
# (NES/SNES Classic) and would override the correct Cortex-A35/ARMv8-A flags.
# HAVE_CLASSIC=1 is kept as it only adds -DHAVE_CLASSIC (currently a no-op
# in upstream v1.22.2 C source, but harmless).
#
# Features enabled to match original PSC binary:
# - SDL2 for input/joystick support
# - Wayland for display
# - Freetype for font rendering
# - OpenGL ES + EGL
# - ALSA audio
# - udev for device hotplug
#
# Build toolchain:
# - crosstool-NG 1.28.0 with GCC 9
# - ARMv8-A architecture (matches original binary)
# - glibc 2.23 (matches PSC)
#
# Optimization flags:
# - -march=armv8-a -mtune=cortex-a35 (PSC CPU)
# - -mfpu=neon-fp-armv8 -mfloat-abi=hard (hardware FPU)
# - -O3 -funroll-loops -ftree-vectorize (aggressive optimization)

TARGET := retroarch

all: $(TARGET)

retroarch:
	export PKG_CONFIG_PATH=/usr/lib/arm-linux-gnueabihf/pkgconfig && \
	export PKG_CONFIG_LIBDIR=/usr/lib/arm-linux-gnueabihf/pkgconfig && \
	export SDL2_CFLAGS="-I/usr/include/arm-linux-gnueabihf/SDL2 -D_REENTRANT" && \
	export SDL2_LIBS="-L/usr/lib/arm-linux-gnueabihf -lSDL2" && \
	export CFLAGS="-march=armv8-a -mtune=cortex-a35 -mfpu=neon-fp-armv8 -mfloat-abi=hard \
		-O3 -fomit-frame-pointer -ffunction-sections -fdata-sections \
		-funroll-loops -ftree-vectorize \
		-I/usr/include/arm-linux-gnueabihf -I/usr/include/arm-linux-gnueabihf/SDL2" && \
	export CXXFLAGS="-march=armv8-a -mtune=cortex-a35 -mfpu=neon-fp-armv8 -mfloat-abi=hard \
		-O3 -fomit-frame-pointer -ffunction-sections -fdata-sections \
		-funroll-loops -ftree-vectorize \
		-I/usr/include/arm-linux-gnueabihf -I/usr/include/arm-linux-gnueabihf/SDL2" && \
	export LDFLAGS="-L/usr/lib/arm-linux-gnueabihf -Wl,-rpath-link,/usr/lib/arm-linux-gnueabihf -Wl,--as-needed -Wl,--allow-shlib-undefined -static-libstdc++ -static-libgcc" && \
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
		--enable-floathard \
		--enable-sdl2 \
		--disable-discord && \
	make HAVE_CLASSIC=1 -j && \
	/opt/x-tools/arm-linux-gnueabihf/bin/arm-linux-gnueabihf-strip -v retroarch

clean:
	rm -rf obj-unix
	rm -f *.d *.o
	rm -f audio/*.o conf/*.o gfx/*.o input/*.o
	rm -f gfx/drivers_font/*.o gfx/drivers_font_renderer/*.o gfx/drivers_context/*.o
	rm -f compat/*.o record/*.o tools/*.o
	rm -f retroarch
