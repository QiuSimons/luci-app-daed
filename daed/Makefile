# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2023 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=daed
PKG_VERSION:=2026.02.07
DAED_VERSION:=daed-f045ecd
WING_VERSION:=wing-6bb6a31
CORE_VERSION:=core-4baacef
WING_HASH_SHORT:=$(shell echo $(WING_VERSION) | cut -d- -f2)
CORE_HASH_SHORT:=$(shell echo $(CORE_VERSION) | cut -d- -f2)
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_PROTO:=git
PKG_SOURCE_VERSION:=f045ecdd76cecce4e887a123dd45a9c25260f773
PKG_SOURCE_URL:=https://github.com/daeuniverse/daed.git
PKG_MIRROR_HASH:=skip

PKG_LICENSE:=AGPL-3.0-only MIT
PKG_LICENSE_FILES:=LICENSE wing/LICENSE
PKG_MAINTAINER:=Tianling Shen <cnsztl@immortalwrt.org>

PKG_BUILD_DIR=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)/wing
PKG_BUILD_DEPENDS:=golang/host bpf-headers
PKG_BUILD_PARALLEL:=1
PKG_BUILD_FLAGS:=no-mips16

GO_PKG:=github.com/daeuniverse/dae-wing
GO_PKG_LDFLAGS:= \
	-s -w -X '$(GO_PKG)/db.AppDescription=$(PKG_NAME) is a integration solution of dae, API and UI.'
GO_PKG_LDFLAGS_X= \
	$(GO_PKG)/db.AppName=$(PKG_NAME) \
	$(GO_PKG)/db.AppVersion=$(DAED_VERSION)_$(WING_VERSION)_$(CORE_VERSION)
GO_PKG_TAGS:=embedallowed,trace

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/bpf.mk
include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk

GO_PKG_TARGET_VARS+= \
	CGO_LDFLAGS="$(TARGET_LDFLAGS) -static" \
	GOEXPERIMENT=newinliner,runtimefreegc,simd
GO_PKG_DEFAULT_LDFLAGS:=-w -s -linkmode external -extldflags '-static'

define Package/daed/Default
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  URL:=https://github.com/daeuniverse/daed
endef

define Package/daed
  $(call Package/daed/Default)
  TITLE:=A Modern Dashboard For dae
  DEPENDS:=$(GO_ARCH_DEPENDS) $(BPF_DEPENDS) \
    +ca-bundle +kmod-sched-core +kmod-sched-bpf +kmod-xdp-sockets-diag \
    +kmod-veth +v2ray-geoip +v2ray-geosite
endef

define Package/daed/description
  daed is a backend of dae, provides a method to bundle arbitrary
  frontend, dae and geodata into one binary.
endef

define Package/daed/conffiles
/etc/daed/wing.db
/etc/config/daed
endef

NODE_VERSION:=v24.12.0
NODE_DIST:=node-$(NODE_VERSION)-linux-x64
NODE_URL:=https://nodejs.org/dist/$(NODE_VERSION)/$(NODE_DIST).tar.xz
# NODE_DIST:=node-$(NODE_VERSION)-linux-x64-musl
# NODE_URL:=https://unofficial-builds.nodejs.org/download/release/$(NODE_VERSION)/$(NODE_DIST).tar.xz

define Build/Prepare
	( \
		$(TAR) --strip-components=1 -C $(PKG_BUILD_DIR)/../ -xzf $(DL_DIR)/$(PKG_NAME)-$(PKG_VERSION).tar.gz ; \
		rm -rf $(PKG_BUILD_DIR) && git clone https://github.com/daeuniverse/dae-wing $(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)/wing && git -C $(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)/wing checkout $(WING_HASH_SHORT) ; \
		rm -rf $(PKG_BUILD_DIR)/dae-core && git clone https://github.com/daeuniverse/dae $(PKG_BUILD_DIR)/dae-core && git -C $(PKG_BUILD_DIR)/dae-core checkout $(CORE_HASH_SHORT) ; \
		pushd $(PKG_BUILD_DIR)/dae-core ; \
		git submodule update --init ; \
		go get -u=patch ; \
		go mod tidy ; \
		popd ; \
		pushd $(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)/wing ; \
		go mod tidy ; \
		popd ; \
		mkdir -p $(PKG_BUILD_DIR)/.node_tmp ; \
		mkdir -p $(PKG_BUILD_DIR)/.node_tmp/config ; \
		wget -qO - "$(NODE_URL)" | tar -xJ -C $(PKG_BUILD_DIR)/.node_tmp --strip-components=1 ; \
		export PATH="$(PKG_BUILD_DIR)/.node_tmp/bin:$$$$PATH" ; \
		export XDG_CONFIG_HOME="$(PKG_BUILD_DIR)/.node_tmp/config" ; \
		npm install -g pnpm ; \
		pushd $(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION) ; \
		pnpm install ; \
		pnpm build --filter daed ; \
		popd ; \
		mkdir -p $(PKG_BUILD_DIR)/webrender/web ; \
		cp -rf $(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)/apps/web/dist/* $(PKG_BUILD_DIR)/webrender/web ; \
		find $(PKG_BUILD_DIR)/webrender/web -type f -size +4k ! -name "*.gz" ! -name "*.woff"  ! -name "*.woff2" -exec sh -c '\
			gzip -9 -k "{}"; \
			if [ "$$$$(stat -c %s {})" -lt "$$$$(stat -c %s {}.gz)" ]; then \
				rm {}.gz; \
			else \
				rm {}; \
			fi' \
		";" ; \
		rm -rf $(PKG_BUILD_DIR)/.node_tmp ; \
	)
endef

DAE_CFLAGS:= \
	-O2 -Wall -Werror \
	-DMAX_MATCH_SET_LEN=1024 \
	-I$(BPF_HEADERS_DIR)/tools/lib \
	-I$(BPF_HEADERS_DIR)/arch/$(BPF_KARCH)/include/asm/mach-generic

define Build/Compile
	( \
		pushd $(PKG_BUILD_DIR) ; \
		export \
		$(GO_GENERAL_BUILD_CONFIG_VARS) \
		$(GO_PKG_BUILD_CONFIG_VARS) \
		$(GO_PKG_BUILD_VARS) ; \
		go generate ./... ; \
		cd dae-core ; \
		export \
		BPF_CLANG="$(CLANG)" \
		BPF_STRIP_FLAG="-strip=$(LLVM_STRIP)" \
		BPF_CFLAGS="$(DAE_CFLAGS)" \
		BPF_TARGET="bpfel,bpfeb" \
		BPF_TRACE_TARGET="$(GO_ARCH)" ; \
		go generate control/control.go ; \
		go generate trace/trace.go ; \
		popd ; \
		$(call GoPackage/Build/Compile) ; \
	)
endef

define Package/daed/install
	$(call GoPackage/Package/Install/Bin,$(PKG_INSTALL_DIR))
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/dae-wing $(1)/usr/bin/daed

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) $(CURDIR)/files/daed.config $(1)/etc/config/daed

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(CURDIR)/files/daed.init $(1)/etc/init.d/daed
endef

$(eval $(call GoBinPackage,daed))
$(eval $(call BuildPackage,daed))
