export CROSS_COMPILE := /home/tudor/Documents/facultate/proiecte/arm-summer-school/src/toolchain/arm-gnu-toolchain-12.2.rel1-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-
export LD_LIBRARY_PATH := 

TEE_TZDRAM_START = 0xbdc00000
TEE_TZDRAM_SIZE = 0x2000000
TEE_SHMEM_START = 0xBFC00000
TEE_SHMEM_SIZE = 0x400000
TEE_RAM_TOTAL_SIZE = 0x2400000


.PHONY: all buildroot optee_client optee_examples clean

# Generare ARM Trusted Firmware
bl31:
	make -C imx-atf/ \
		PLAT=imx8mq \
		SPD=opteed \
		BL32_BASE=${TEE_TZDRAM_START} \
		BL32_SIZE=${TEE_RAM_TOTAL_SIZE} \
		LOG_LEVEL=40 \
		IMX_BOOT_UART_BASE=0x30860000 \
		bl31

# Compilare trusted kernel (bl32)
op-tee:
	make -C optee_os -j 16 \
		DEBUG=1 \
		O=out/arm \
		CFG_TEE_BENCHMARK=n \
		CFG_TEE_CORE_LOG_LEVEL=3 \
		PLATFORM=imx-mx8mqevk \
		CFG_TZDRAM_START=${TEE_TZDRAM_START} \
		CFG_TZDRAM_SIZE=${TEE_TZDRAM_SIZE} \
		CFG_TEE_SHMEM_START=${TEE_SHMEM_START} \
		CFG_TEE_SHMEM_SIZE=${TEE_SHMEM_SIZE} \
		CFG_DDR_SIZE=0x80000000 \
		CROSS_COMPILE=${CROSS_COMPILE} \
		CROSS_COMPILE_core=$(CROSS_COMPILE) \
		CROSS_COMPILE_ta_arm64=${CROSS_COMPILE} \
		CFG_UART_BASE=0x30860000


# Compilare u-boot (bl2 si bl33)
uboot:
	make -C u-boot-tn-imx/ -j 16

# Generare firmware image package
mkimage:
	cp firmware/ddr/synopsys/lpddr4_pmu_train_1d_dmem.bin imx-mkimage/iMX8M/
	cp firmware/ddr/synopsys/lpddr4_pmu_train_1d_imem.bin imx-mkimage/iMX8M/
	cp firmware/ddr/synopsys/lpddr4_pmu_train_2d_dmem.bin imx-mkimage/iMX8M/
	cp firmware/ddr/synopsys/lpddr4_pmu_train_2d_imem.bin imx-mkimage/iMX8M/
	cp firmware/hdmi/cadence/signed_hdmi_imx8m.bin imx-mkimage/iMX8M/
	
	cp imx-atf/build/imx8mq/release/bl31.bin imx-mkimage/iMX8M/
	cp optee_os/out/arm/core/tee-raw.bin imx-mkimage/iMX8M/tee.bin
	
	cp u-boot-tn-imx/u-boot-nodtb.bin imx-mkimage/iMX8M/
	cp u-boot-tn-imx/spl/u-boot-spl.bin imx-mkimage/iMX8M/
	cp u-boot-tn-imx/arch/arm/dts/imx8mq-pico-pi.dtb imx-mkimage/iMX8M/
	cp u-boot-tn-imx/tools/mkimage imx-mkimage/iMX8M/mkimage_uboot
	
	make -C imx-mkimage/ SOC=iMX8M dtbs=imx8mq-pico-pi.dtb TEE_LOAD_ADDR=$(TEE_TZDRAM_START) flash_evk

# Rulare u-boot pe board
run-uboot:
	sudo mfgtools/build/uuu/uuu -b spl imx-mkimage/iMX8M/flash.bin

# Compilare kernel
linux:
	make -C linux/ ARCH=arm64 defconfig
	make -C linux/ -j 16 ARCH=arm64
	# arch/arm64/boot/Image
	# arch/arm64/boot/dts/freescale/imx8mq-pico-pi.dtb

# Compilare device tree
linux-dtb:
	make -C linux/ ARCH=arm64 dtbs

# Compilare buildroot pentru rootfs
buildroot:
	make -C buildroot/
	# output/images/rootfs.cpio

# Creare imagine disk (trebuie păstrat un offset de 10M pentru zona de configurare)
create-img:
	rm -f staging/disk.img
	truncate --size 150M staging/disk.img
	(\
		echo o # Create a new empty DOS partition table\
		echo n # Add a new partition\
		echo p # Primary partition\
		echo 1 # Partition number\
		echo 20480 # First sector (10M offset)\
		echo   # Last sector (Accept default)\
		echo w # Write changes\
	) | fdisk staging/disk.img
	sudo partx -a -v staging/disk.img
	sudo mkfs.fat -F 32 /dev/loop0p1

# Atasare imagine la device loop
attach-img:
	sudo partx -a -v staging/disk.img

# Detasare imagine
detach-img:
	-sudo partx -d /dev/loop0p1
	sudo losetup -D /dev/loop0

# Generare imagine disk cu flatened image tree
fit:
	cp linux/arch/arm64/boot/Image staging/
	cp linux/arch/arm64/boot/dts/freescale/imx8mq-pico-pi.dtb staging/
	cp buildroot/output/images/rootfs.cpio staging/

	mkimage -f staging/linux.its staging/linux.itb
	
	sudo mount /dev/loop0p1 /mnt
	-sudo cp staging/linux.itb /mnt/
	sudo umount /mnt

# Incarcare imagine pe board
upload-image:
	sudo mfgtools/build/uuu/uuu -b emmc_all imx-mkimage/iMX8M/flash.bin staging/disk.img

# Compilare client OP-TEE
optee_client:
	mkdir optee_client/build
	cmake -DCMAKE_C_COMPILER=${CROSS_COMPILE}gcc -DCMAKE_INSTALL_PREFIX=optee_client/build/dist/  -B optee_client/build -S optee_client
	make -C optee_client/build
	make -C optee_client/build install

# Compilare exemplu de trusted application
optee_examples:
	make -C optee_examples/hello_world/host TEEC_EXPORT=../../../optee_client/build/dist --no-builtin-variables
	make -C optee_examples/hello_world/ta PLATFORM=imx-mx8mqevk TA_DEV_KIT_DIR=../../../optee_os/out/arm/export-ta_arm64/

# Compilare modul kernel
uart-module:
	make -C kernel-module build

# Curatare build
clean:
	make -C imx-atf/ clean
	make -C u-boot-tn-imx/ clean
	make -C imx-mkimage/ clean
	rm imx-mkimage/iMX8M/lpddr4_pmu_train_1d_dmem.bin
	rm imx-mkimage/iMX8M/lpddr4_pmu_train_1d_imem.bin
	rm imx-mkimage/iMX8M/lpddr4_pmu_train_2d_dmem.bin
	rm imx-mkimage/iMX8M/lpddr4_pmu_train_2d_imem.bin
	rm imx-mkimage/iMX8M/signed_hdmi_imx8m.bin
	rm imx-mkimage/iMX8M/bl31.bin
	rm imx-mkimage/iMX8M/u-boot-nodtb.bin
	rm imx-mkimage/iMX8M/u-boot-spl.bin
	rm imx-mkimage/iMX8M/imx8mq-pico-pi.dtb
	rm imx-mkimage/iMX8M/mkimage_uboot
	rm staging/Image
	rm staging/imx8mq-pico-pi.dtb
	rm staging/rootfs.cpio
	rm staging/linux.itb
	make -C optee_os O=out/arm PLATFORM=imx-mx8mqevk clean
	rm -rf optee_client/build
	make -C optee_examples/hello_world/host TEEC_EXPORT=../../../optee-client/build/dist clean
	make -C optee_examples/hello_world/ta TA_DEV_KIT_DIR=../../../optee_os/out/arm/export-ta_arm64/ clean
	make -C kernel-module clean
