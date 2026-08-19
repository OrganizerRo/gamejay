################################################################################
#
# gamejay-prebuilt-cores
#
################################################################################

GAMEJAY_PREBUILT_CORES_VERSION = $(shell $(BR2_EXTERNAL_GAMEJAY_PATH)/support/gamejay-dependency-id.sh cores)
GAMEJAY_PREBUILT_CORES_SITE = $(BR2_EXTERNAL_GAMEJAY_PATH)/.prebuilt/cores
GAMEJAY_PREBUILT_CORES_SITE_METHOD = local
GAMEJAY_PREBUILT_CORES_LICENSE = GPL-2.0, Snes9x non-commercial, MAME non-commercial
GAMEJAY_PREBUILT_CORES_REDISTRIBUTE = NO

define GAMEJAY_PREBUILT_CORES_INSTALL_TARGET_CMDS
	$(INSTALL) -d $(TARGET_DIR)/usr/lib/libretro
	$(INSTALL) -m 0755 $(@D)/*_libretro.so $(TARGET_DIR)/usr/lib/libretro/
endef

$(eval $(generic-package))
