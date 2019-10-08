build-all:
	nasm Source/MBR-Bootloader.asm -o BinaryFiles/MBR-Bootloader.bin
	nasm Source/FAT32-Bootloader.asm -o BinaryFiles/FAT32-Bootloader.bin

drive = ''

burn-mbr-bootloader:
	@if [ $(drive) = '' ]; then \
		echo "No drive specified, terminating"; \
		echo "	Note: specify drive (ex. drive=/dev/sdc)"; \
		echo "	Note: please be very careful in drive selection; this command could make your hardrive unbootable"; \
	else \
		dd if=$(drive) of=inputDisk_Bootloader.temporary bs=1 count=512; \
		dd if=BinaryFiles/MBR-Bootloader.bin of=inputDisk_Bootloader.temporary bs=1 count=440 conv=notrunc; \
		dd if=BinaryFiles/MBR-Bootloader.bin of=inputDisk_Bootloader.temporary bs=1 skip=510 seek=510 count=2 conv=notrunc; \
		dd if=inputDisk_Bootloader.temporary of=$(drive) bs=1 count=512 conv=notrunc; \
		rm inputDisk_Bootloader.temporary; \
	fi

burn-fat32-bootloader:
	@if [ $(drive) = '' ]; then \
		echo "No drive specified, terminating"; \
		echo "	Note: specify drive (ex. drive=/dev/sdc1)"; \
		echo "	Note: please be very careful in drive selection; this command could make your hardrive unbootable"; \
	else \
		dd if=$(drive) of=inputDisk_Bootloader.temporary bs=1 count=512; \
		dd if=BinaryFiles/FAT32-Bootloader.bin of=inputDisk_Bootloader.temporary bs=1 count=3 conv=notrunc; \
		dd if=BinaryFiles/FAT32-Bootloader.bin of=inputDisk_Bootloader.temporary bs=1 skip=90 seek=90 count=420 conv=notrunc; \
		dd if=inputDisk_Bootloader.temporary of=$(drive) bs=1 count=512 conv=notrunc; \
		sync $(drive); \
		rm inputDisk_Bootloader.temporary; \
	fi