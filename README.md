# ARM summer school
## Descriere
Compilare și testare firmware și OS pentru placă development TechNexion Pico Pi IMX8M, în cadrul ARM Development Google Summer School.

Documentație prezentări și laborator: https://ocw.cs.pub.ro/courses/ass.

## Componente
- `buildroot` (https://github.com/buildroot/buildroot): construiește rootfs-ul pentru inițializarea imaginii de linux (cu toate utilitarele și aplicațiile instalate)
- `firmware` (http://sources.buildroot.net/firmware-imx/): firmware binar pentru diverse componente de pe placă
- `imx-atf` (https://github.com/nxp-imx/imx-atf): arm trusted firmware, fork pentru ixm (firmware-ul care rulează la nivelul BL31)
- `imx-mkimage` (https://github.com/nxp-imx/imx-mkimage): generarea firmware package-ului (`flash.bin`) care încarcă BL2 (din uboot), BL31 (din atf) și BL33 (bootloaderul uboot)
- `kernel-module`: exemplu de modul de kernel care interacționează cu interfața UART a microprocesorului
- `linux`: kernelul de Linux (cu patch pentru generarea device tree-ului corect) (la tag-ul `v6.5-rc2`)
- `mfgtools` (https://github.com/nxp-imx/mfgtools): utilitarul `uuu` care permite flash-uirea firmware-ului pe board
- `optee_client` (https://github.com/OP-TEE/optee_client): driver din cadrul op-tee care rulează în partea de kernel unsecure și permite interacțiunea cu trusted applications din componenta secure prin memorie partajată
- `optee_os` (https://github.com/OP-TEE/optee_os/): kernelul trusted care se încarcă în zona secure (la nivel de privilegiu EL1)
- `staging`: pregătirea imaginii FIT și punerea acesteia într-o imagine de disk pentru flash pe mmc
- `toolchain`: toolchain de cross compiling pentru arhitectura armv8 (aarch64) (arm-gnu-toolchain-12.2.rel1-x86_64-aarch64-none-linux-gnu)
- `u-boot-tn-imx`: bootloaderul u-boot care generează firmware-ul bl2 și bl33 și pregătește inițializarea kenrelului (configurat pentru permiterea unui kernel mai mare de 8MB)

- `configs`: configurările de compilare și patch-urile aplicate pentru kernel, uboot și buildroot