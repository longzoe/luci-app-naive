include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-naive
PKG_VERSION:=1.1.0
PKG_RELEASE:=2

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-naive
  SECTION:=luci
  CATEGORY:=LuCI
  TITLE:=NaiveProxy LuCI App
  DEPENDS:=+luci-base
endef

define Package/luci-app-naive/description
  LuCI app for configuring and managing a manually installed NaiveProxy client on OpenWrt.
endef

define Package/luci-app-naive/conffiles
/etc/config/naive
endef

define Build/Compile
endef

define Package/luci-app-naive/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_BIN) ./luasrc/controller/naive.lua $(1)/usr/lib/lua/luci/controller/naive.lua

	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/naive
	$(INSTALL_BIN) ./luasrc/model/cbi/naive/config.lua $(1)/usr/lib/lua/luci/model/cbi/naive/config.lua

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./root/etc/init.d/naive $(1)/etc/init.d/naive

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./root/etc/config/naive $(1)/etc/config/naive
endef

$(eval $(call BuildPackage,luci-app-naive))
