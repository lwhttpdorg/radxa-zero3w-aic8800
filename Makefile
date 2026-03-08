SHELL := /bin/bash

# SDIO driver source directory (new top-level layout)
SDIO_DRV_DIR := $(CURDIR)/SDIO/driver_fw/driver/aic8800
SDIO_FW_DIR  := $(CURDIR)/SDIO/driver_fw/fw

# Build options (override from command line)
ARCH ?=
CROSS_COMPILE ?=
KDIR ?= /lib/modules/$(shell uname -r)/build

# Install options (override from command line)
# Example:
#   make install INSTALL_PATH=/mnt/zero3w-rootfs
INSTALL_PATH ?= /
KERNELRELEASE ?= $(shell $(MAKE) -s -C "$(KDIR)" kernelrelease 2>/dev/null)
MOD_DEST ?= $(INSTALL_PATH)/lib/modules/$(KERNELRELEASE)/extra
FW_DEST ?= $(INSTALL_PATH)/lib/firmware/aic8800_fw/SDIO

MODULES := \
	$(SDIO_DRV_DIR)/aic8800_bsp/aic8800_bsp.ko \
	$(SDIO_DRV_DIR)/aic8800_fdrv/aic8800_fdrv.ko \
	$(SDIO_DRV_DIR)/aic8800_btlpm/aic8800_btlpm.ko

KBUILD_OPTS := M="$(SDIO_DRV_DIR)"
ifneq ($(strip $(ARCH)),)
KBUILD_OPTS += ARCH="$(ARCH)"
endif
ifneq ($(strip $(CROSS_COMPILE)),)
KBUILD_OPTS += CROSS_COMPILE="$(CROSS_COMPILE)"
endif

.DEFAULT_GOAL := build

.PHONY: help build install clean

help:
	@echo "Targets:"
	@echo "  build    - Build SDIO kernel modules"
	@echo "  install  - Install modules + firmware to INSTALL_PATH"
	@echo "  clean    - Clean SDIO module build outputs"
	@echo
	@echo "Variables:"
	@echo "  KDIR=<kernel source/build path>"
	@echo "  ARCH=<target arch> (default: host/native)"
	@echo "  CROSS_COMPILE=<toolchain prefix> (default: host/native)"
	@echo "  INSTALL_PATH=<root path to install into> (default: $(INSTALL_PATH))"
	@echo
	@echo "Examples:"
	@echo "  make KDIR=/home/user/linux-main"
	@echo "  make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- KDIR=/home/user/linux-main"
	@echo "  make install KDIR=/home/user/linux-main INSTALL_PATH=/mnt/rootfs"

build:
	@echo "[BUILD] KDIR=$(KDIR)"
	$(MAKE) -C "$(KDIR)" $(KBUILD_OPTS) modules

install: build
	@echo "[INSTALL] modules -> $(MOD_DEST)"
	@echo "[INSTALL] firmware -> $(FW_DEST)"
	mkdir -p "$(MOD_DEST)"
	mkdir -p "$(FW_DEST)"
	cp -av $(MODULES) "$(MOD_DEST)/"
	cp -av "$(SDIO_FW_DIR)/." "$(FW_DEST)/"
	@if [ -n "$(KERNELRELEASE)" ] && command -v depmod >/dev/null 2>&1; then \
		echo "[INSTALL] depmod -b $(INSTALL_PATH) $(KERNELRELEASE)"; \
		depmod -b "$(INSTALL_PATH)" "$(KERNELRELEASE)" || true; \
	else \
		echo "[INSTALL] skip depmod (KERNELRELEASE unknown or depmod missing)"; \
	fi

clean:
	$(MAKE) -C "$(KDIR)" $(KBUILD_OPTS) clean

