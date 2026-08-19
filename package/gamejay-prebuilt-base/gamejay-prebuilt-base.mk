################################################################################
#
# gamejay-prebuilt-base
#
################################################################################

GAMEJAY_PREBUILT_BASE_VERSION = $(shell $(BR2_EXTERNAL_GAMEJAY_PATH)/support/gamejay-dependency-id.sh base)
GAMEJAY_PREBUILT_BASE_SITE = $(BR2_EXTERNAL_GAMEJAY_PATH)/.prebuilt/base
GAMEJAY_PREBUILT_BASE_SITE_METHOD = local
GAMEJAY_PREBUILT_BASE_INSTALL_STAGING = YES
GAMEJAY_PREBUILT_BASE_LICENSE = Various
GAMEJAY_PREBUILT_BASE_REDISTRIBUTE = NO

define GAMEJAY_PREBUILT_BASE_INSTALL_STAGING_CMDS
	cp -a $(@D)/staging/. $(STAGING_DIR)/
endef

define GAMEJAY_PREBUILT_BASE_INSTALL_TARGET_CMDS
	cp -a $(@D)/target/. $(TARGET_DIR)/
	cp -a $(@D)/images/. $(BINARIES_DIR)/
endef

$(eval $(generic-package))
