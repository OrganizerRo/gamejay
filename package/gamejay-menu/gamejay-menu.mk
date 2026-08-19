################################################################################
#
# gamejay-menu
#
################################################################################

GAMEJAY_MENU_VERSION = 1.0.0
GAMEJAY_MENU_SITE = $(BR2_EXTERNAL_GAMEJAY_PATH)/package/gamejay-menu/src
GAMEJAY_MENU_SITE_METHOD = local
GAMEJAY_MENU_DEPENDENCIES = gamejay-prebuilt-base host-pkgconf

define GAMEJAY_MENU_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(@D)
endef

define GAMEJAY_MENU_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/gamejay-menu \
		$(TARGET_DIR)/usr/bin/gamejay-menu
endef

$(eval $(generic-package))
