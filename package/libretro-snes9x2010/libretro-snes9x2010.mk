################################################################################
#
# libretro-snes9x2010
#
################################################################################

LIBRETRO_SNES9X2010_VERSION = 7db129b1ecdccb38cb4d7184bcbed39beed79656
LIBRETRO_SNES9X2010_SITE = $(call github,libretro,snes9x2010,$(LIBRETRO_SNES9X2010_VERSION))
LIBRETRO_SNES9X2010_LICENSE = Non-commercial
LIBRETRO_SNES9X2010_LICENSE_FILES = LICENSE.txt

define LIBRETRO_SNES9X2010_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) \
		CC="$(TARGET_CC)" CXX="$(TARGET_CXX)" AR="$(TARGET_AR)" \
		LD="$(TARGET_CC)" RANLIB="$(TARGET_RANLIB)" \
		STRIP="$(TARGET_STRIP)" LTO= platform=unix
endef

define LIBRETRO_SNES9X2010_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/snes9x2010_libretro.so \
		$(TARGET_DIR)/usr/lib/libretro/snes9x2010_libretro.so
endef

$(eval $(generic-package))
