.PHONY: utilities
all: build_dir build/boot.bin build/kernel.bin image.iso run

ISO_DIR = iso
BUILD_DIR = build

BOOT_STAGE_INCLUDE = common

run:
	qemu-system-x86_64 -cdrom image.iso

build_dir:
	mkdir -p $(BUILD_DIR)

image.iso:
	mkdir -p $(ISO_DIR)/
	cp $(BUILD_DIR)/boot.bin $(ISO_DIR)/
	cp ab.txt $(ISO_DIR)/
	cp $(BUILD_DIR)/kernel.bin $(ISO_DIR)/

	xorriso -as mkisofs -R -J -b boot.bin -no-emul-boot -boot-load-size 4 -o $@ $(ISO_DIR)

build/boot.bin: boot.asm
	nasm -f bin -I $(BOOT_STAGE_INCLUDE) -o $@ $<

build/kernel.bin: kernel.asm
	nasm -f bin -o $@ $<

ISO9660:
	$(MAKE) -C utilities ISO9660

ISO9660_run:
	$(MAKE) -C utilities run

clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(ISO_DIR)
	rm -rf image.iso
	$(MAKE) -C utilities clean 
