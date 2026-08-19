################################################################################
#
# retroarch
#
################################################################################

RETROARCH_VERSION = 250919d9c4851e7389d45952fd7f08d60efc0b3d
RETROARCH_SITE = $(call github,libretro,RetroArch,$(RETROARCH_VERSION))
RETROARCH_LICENSE = GPL-3.0
RETROARCH_LICENSE_FILES = COPYING
RETROARCH_DEPENDENCIES = alsa-lib libdrm libevdev mesa3d sdl2 udev

define RETROARCH_CONFIGURE_CMDS
	(cd $(@D) && \
		$(TARGET_CONFIGURE_OPTS) \
		PKG_CONFIG="$(PKG_CONFIG_HOST_BINARY)" \
		./configure \
			--host=$(GNU_TARGET_NAME) \
			--prefix=/usr \
			--disable-x11 \
			--disable-wayland \
			--disable-qt \
			--disable-vulkan \
			--disable-ffmpeg \
			--enable-alsa \
			--enable-dynamic \
			--enable-egl \
			--enable-kms \
			--enable-opengles \
			--enable-sdl2 \
			--enable-udev)
endef

define RETROARCH_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(@D)
endef

define RETROARCH_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/retroarch \
		$(TARGET_DIR)/usr/bin/retroarch
endef

$(eval $(generic-package))
