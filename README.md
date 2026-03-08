# radxa-zero3w aic8800 Wi-Fi Driver

This repository provides the `aic8800` wireless (Wi-Fi) driver for `radxa-zero3w`, with SDIO build/install helpers.

## 1. Prerequisites

- Linux kernel 6.1 or newer
- Kernel source/build tree for your target (`KDIR`)

## 2. Build

Command-line Variables:

- `ARCH`: target CPU architecture passed to kernel build system (for example `arm64`). If not set, native host build is used.
- `CROSS_COMPILE`: cross-toolchain prefix used by GCC/binutils (for example `aarch64-linux-gnu-` or `aarch64-none-linux-gnu-`). If not set, native host compiler is used.
- `KDIR`: path to the target kernel source/build tree (`include`, `Module.symvers`, and kernel build scripts are read from here).
- `BUILD_DIR`: output directory for `.o`/`.ko` files (default: `./build`). Source tree stays clean.
- `INSTALL_PATH`: root path where `make install` copies outputs (for example `/mnt/rootfs`); modules/firmware are installed under this root.

Cross-compile examples:

- `ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-`
- `ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu-` (Arm GNU Toolchain Downloads prefix)

`aarch64-none-linux-gnu-` is the prefix used by Arm official toolchains from Arm GNU Toolchain Downloads.

Build SDIO modules against a specific kernel tree:

```bash
make KDIR=/path/to/linux-kernel
```

Cross-compile example:

```bash
make ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- KDIR=/path/to/linux-kernel
```

Produced modules (in `build/` by default):

- `build/aic8800_bsp/aic8800_bsp.ko`
- `build/aic8800_fdrv/aic8800_fdrv.ko`
- `build/aic8800_btlpm/aic8800_btlpm.ko`

## 3. Install

Install modules + firmware into a target rootfs path:

```bash
make install ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- KDIR=/path/to/linux-kernel INSTALL_PATH=/mnt/rootfs
```

Install destinations:

- Modules: `/lib/modules/<kernelrelease>/extra`
- Firmware: `/lib/firmware/aic8800_fw/SDIO`

If available, `depmod` is run with `-b INSTALL_PATH`.

## 4. Uninstall

Remove installed modules and firmware:

```bash
make uninstall KDIR=/path/to/linux-kernel INSTALL_PATH=/mnt/rootfs
```

Runs `depmod` after removal when available.

## 5. Clean

```bash
make clean ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- KDIR=/path/to/linux-kernel
```

Removes build artifacts and deletes the `build/` directory.
