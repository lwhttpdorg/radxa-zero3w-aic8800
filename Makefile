SHELL := /bin/bash

# SDIO driver source directory (new top-level layout)
SDIO_DRV_DIR := $(CURDIR)/SDIO/driver_fw/driver/aic8800
SDIO_FW_DIR  := $(CURDIR)/SDIO/driver_fw/fw

# Build options (override from command line)
ARCH ?=
CROSS_COMPILE ?=
KDIR ?= /lib/modules/$(shell uname -r)/build
BUILD_DIR ?= $(CURDIR)/build

# Install options (override from command line)
# Example:
#   make install INSTALL_PATH=/mnt/zero3w-rootfs
INSTALL_PATH ?= /
INSTALL_MOD_PATH ?= $(INSTALL_PATH)
KERNELRELEASE ?= $(shell $(MAKE) -s -C "$(KDIR)" kernelrelease 2>/dev/null)
MOD_DEST ?= $(INSTALL_PATH)/lib/modules/$(KERNELRELEASE)/extra
FW_DEST ?= $(INSTALL_PATH)/lib/firmware/aic8800_fw/SDIO

KBUILD_OPTS := M="$(SDIO_DRV_DIR)" MO="$(BUILD_DIR)"
ifneq ($(strip $(ARCH)),)
KBUILD_OPTS += ARCH="$(ARCH)"
endif
ifneq ($(strip $(CROSS_COMPILE)),)
KBUILD_OPTS += CROSS_COMPILE="$(CROSS_COMPILE)"
endif

.DEFAULT_GOAL := build

.PHONY: help build install uninstall clean

help:
	@echo "Targets:"
	@echo "  build     - Build SDIO kernel modules"
	@echo "  install   - Install modules + firmware to INSTALL_PATH"
	@echo "  uninstall - Remove installed modules + firmware"
	@echo "  clean     - Clean SDIO module build outputs"
	@echo
	@echo "Variables:"
	@echo "  KDIR=<kernel source/build path>"
	@echo "  ARCH=<target arch> (default: host/native)"
	@echo "  CROSS_COMPILE=<toolchain prefix> (default: host/native)"
	@echo "  BUILD_DIR=<output directory for .o/.ko etc> (default: $(BUILD_DIR))"
	@echo "  INSTALL_PATH=<root path to install into> (default: $(INSTALL_PATH))"
	@echo "  INSTALL_MOD_PATH=<same as INSTALL_PATH, for module install prefix>"
	@echo
	@echo "Examples:"
	@echo "  make KDIR=/home/user/linux-main"
	@echo "  make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- KDIR=/home/user/linux-main"
	@echo "  make install KDIR=/home/user/linux-main INSTALL_PATH=/mnt/rootfs"
	@echo "  make uninstall KDIR=/home/user/linux-main INSTALL_PATH=/mnt/rootfs"

build:
	@echo "[BUILD] KDIR=$(KDIR) OUTPUT=$(BUILD_DIR)"
	@# Clean source dir if it has leftover artifacts (required when using MO=)
	-$(MAKE) -C "$(KDIR)" M="$(SDIO_DRV_DIR)" $(if $(strip $(ARCH)),ARCH="$(ARCH)",) $(if $(strip $(CROSS_COMPILE)),CROSS_COMPILE="$(CROSS_COMPILE)",) clean 2>/dev/null || true
	mkdir -p "$(BUILD_DIR)"
	$(MAKE) -C "$(KDIR)" $(KBUILD_OPTS) modules

install: build
	@echo "[INSTALL] modules -> $(INSTALL_MOD_PATH)/lib/modules/$(KERNELRELEASE)/extra"
	@echo "[INSTALL] firmware -> $(FW_DEST)"
	$(MAKE) -C "$(KDIR)" $(KBUILD_OPTS) modules_install INSTALL_MOD_PATH="$(INSTALL_MOD_PATH)" INSTALL_MOD_DIR=extra
	mkdir -p "$(FW_DEST)"
	cp -a "$(SDIO_FW_DIR)/." "$(FW_DEST)/"

uninstall:
	@echo "[UNINSTALL] modules from $(INSTALL_MOD_PATH)/lib/modules/$(KERNELRELEASE)/extra"
	@echo "[UNINSTALL] firmware from $(FW_DEST)"
	rm -rf "$(INSTALL_MOD_PATH)/lib/modules/$(KERNELRELEASE)/extra/aic8800_bsp"
	rm -rf "$(INSTALL_MOD_PATH)/lib/modules/$(KERNELRELEASE)/extra/aic8800_fdrv"
	rm -rf "$(INSTALL_MOD_PATH)/lib/modules/$(KERNELRELEASE)/extra/aic8800_btlpm"
	rm -rf "$(FW_DEST)"
	@if [ -n "$(KERNELRELEASE)" ] && command -v depmod >/dev/null 2>&1; then \
		echo "[UNINSTALL] depmod -b $(INSTALL_MOD_PATH) $(KERNELRELEASE)"; \
		depmod -b "$(INSTALL_MOD_PATH)" "$(KERNELRELEASE)" || true; \
	fi

clean:
	$(MAKE) -C "$(KDIR)" $(KBUILD_OPTS) clean
	rm -rf "$(BUILD_DIR)"

