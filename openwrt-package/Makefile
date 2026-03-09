#
# Copyright (C) 2025 ZeroClaw Labs
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=zeroclaw
PKG_VERSION:=0.1.7
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/zeroclaw-labs/zeroclaw.git
PKG_SOURCE_VERSION:=$(PKG_VERSION)
PKG_MIRROR_HASH:=skip

PKG_LICENSE:=MIT OR Apache-2.0
PKG_LICENSE_FILES:=LICENSE-MIT LICENSE-APACHE
PKG_MAINTAINER:=ZeroClaw Labs <opensource@zeroclaw.io>

PKG_BUILD_PARALLEL:=1
PKG_BUILD_DEPENDS:=rust/host cargo/host

include $(INCLUDE_DIR)/package.mk

define Package/zeroclaw
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=ZeroClaw AI Agent Runtime
  URL:=https://github.com/zeroclaw-labs/zeroclaw
  DEPENDS:=+ca-bundle +libopenssl \
           @(TARGET_rockchip_armv8||TARGET_aarch64_generic)
  MENU:=1
endef

define Package/zeroclaw/description
  ZeroClaw is a high-performance AI agent runtime written in Rust.
  Optimized for embedded systems and routers.
endef

define Package/zeroclaw/config
  source "$(SOURCE)/Config.in"
endef

# 使用预编译的静态二进制
define Build/Compile
  $(CP) ./files/zeroclaw $(PKG_BUILD_DIR)/
endef

define Package/zeroclaw/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/zeroclaw $(1)/usr/bin/zeroclaw

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/zeroclaw.config $(1)/etc/config/zeroclaw

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/zeroclaw.init $(1)/etc/init.d/zeroclaw
endef

$(eval $(call BuildPackage,zeroclaw))
