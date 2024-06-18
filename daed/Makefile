# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2023 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=daed
PKG_VERSION=740cf42
DAED_VERSION=daed-740cf42
CORE_VERSION=core-3fd2826
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/daeuniverse/daed.git
PKG_SOURCE_VERSION:=740cf4298d044720afd7647b69f5e17ee7d89f87
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
	-X '$(GO_PKG)/db.AppDescription=$(PKG_NAME) is a integration solution of dae, API and UI.'
GO_PKG_LDFLAGS_X= \
	$(GO_PKG)/db.AppName=$(PKG_NAME) \
	$(GO_PKG)/db.AppVersion=$(DAED_VERSION)_$(CORE_VERSION)
GO_PKG_TAGS:=embedallowed,trace
GO_PKG_GCFLAGS:=-l=4

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/bpf.mk
include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk

TAR_CMD=$(HOST_TAR) -C $(BUILD_DIR)/ $(TAR_OPTIONS)

define Package/daed/Default
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  URL:=https://github.com/daeuniverse/daed
endef

define Package/daed
  $(call Package/daed/Default)
  TITLE:=A Modern Dashboard For dae
  # You need enable KERNEL_DEBUG_INFO_BTF and KERNEL_BPF_EVENTS
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

define Build/Prepare
	$(call Build/Prepare/Default)

	( \
		curl -L -o $(DL_DIR)/web.zip $(curl -s https://api.github.com/repos/daeuniverse/daed/releases | grep -oP '"browser_download_url": "\K[^"]*web.zip' | head -n 1) ; \
		mkdir -p $(PKG_BUILD_DIR)/webrender ; \
		unzip -q -d $(PKG_BUILD_DIR)/webrender/ $(DL_DIR)/web.zip ; \
		find $(PKG_BUILD_DIR)/webrender/web -type f -size +4k ! -name "*.gz" ! -name "*.woff"  ! -name "*.woff2" -exec sh -c '\
			gzip -9 -k "{}"; \
			if [ "$$$$(stat -c %s "{}")" -lt "$$$$(stat -c %s "{}.gz")" ]; then \
				rm "{}.gz"; \
			else \
				rm "{}"; \
			fi' \
		";" ; \
		rm -rf $(PKG_BUILD_DIR) && git clone https://github.com/daeuniverse/dae-wing $(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)/wing ; \
		rm -rf $(PKG_BUILD_DIR)/dae-core && git clone https://github.com/daeuniverse/dae $(PKG_BUILD_DIR)/dae-core ; \
		rm -rf $(PKG_BUILD_DIR)/dae-core/control/kern/headers && git clone https://github.com/daeuniverse/dae_bpf_headers $(PKG_BUILD_DIR)/dae-core/control/kern/headers ; \
		pushd $(PKG_BUILD_DIR)/dae-core ; \
		sed -i -e 's!default:"30s"!default:"600s"!g' -e 's!default:"HEAD"!default:"CONNECT"!g' -e 's!default:"dns.google.com:53,8.8.8.8,2001:4860:4860::8888"!default:"one.one.one.one:53,1.0.0.1,2606:4700:4700::1111"!g' -e 's!default:"http://cp.cloudflare.com,1.1.1.1,2606:4700:4700::1111"!default:"http://cp.cloudflare.com,1.0.0.1,2606:4700:4700::1111"!g' config/config.go ; \
		go get -u=patch ; \
		go mod tidy ; \
		popd ; \
		pushd $(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)/wing ; \
		wget -qO - https://github.com/daeuniverse/dae-wing/commit/ca0296173d36746335efed1923ff08c1300f7a61.patch | patch -p1 ; \
		go get -u=patch ; \
		go mod tidy ; \
		popd ; \
	)
endef

DAE_CFLAGS:= \
	-O2 -Wall -Werror \
	-DMAX_MATCH_SET_LEN=64 \
	-I$(BPF_HEADERS_DIR)/tools/lib \
	-I$(BPF_HEADERS_DIR)/arch/$(BPF_KARCH)/include/asm/mach-generic

ifneq ($(CONFIG_USE_MUSL),)
  TARGET_CFLAGS += -D_LARGEFILE64_SOURCE
endif

define Build/Compile
	( \
		pushd $(PKG_BUILD_DIR) ; \
		export \
		$(GO_GENERAL_BUILD_CONFIG_VARS) \
		$(GO_PKG_BUILD_CONFIG_VARS) \
		$(GO_PKG_BUILD_VARS); \
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