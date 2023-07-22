KDIR ?= ../linux/
export CROSS_COMPILE := /home/tudor/Documents/facultate/proiecte/arm-summer-school/src/toolchain/arm-gnu-toolchain-12.2.rel1-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-

obj-m += uart-module.o

build:
	$(MAKE) ARCH=arm64 -C ${KDIR} M=${PWD} modules

prepare:
	$(MAKE) ARCH=arm64 -C ${KDIR} modules_prepare

clean:
	$(MAKE) ARCH=arm64 -C ${KDIR} M=${PWD} clean
