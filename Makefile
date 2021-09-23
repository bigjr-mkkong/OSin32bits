ENTRYPOINT	= 0x1000

# Offset of entry point in kernel file
# It depends on ENTRYPOINT
ENTRYOFFSET	=   0x400

# Programs, flags, etc.
ASM		= nasm
DASM		= ndisasm
CC		= gcc
LD		= ld
ASMBFLAGS	= -I boot/include/
ASMKFLAGS	= -I include/ -f elf
CFLAGS		= -I include/ -c -fno-builtin -m32 -fno-stack-protector
LDFLAGS		= -s -Ttext $(ENTRYPOINT) -m elf_i386
DASMFLAGS	= -u -o $(ENTRYPOINT) -e $(ENTRYOFFSET)

# This Program
ORANGESBOOT	= boot/boot.bin boot/loader.bin
ORANGESKERNEL	= kernel.bin
OBJS		= kernel/kernel.o lib/syscall.o kernel/start.o kernel/main.o\
			kernel/clock.o kernel/keyboard.o kernel/tty.o kernel/console.o\
			kernel/i8259.o kernel/global.o kernel/protect.o kernel/proc.o\
			kernel/systask.o kernel/hd.o kernel/command.o\
			lib/printf.o lib/vsprintf.o\
			lib/kliba.o lib/klib.o lib/string.o lib/misc.o\
			lib/open.o lib/read.o lib/write.o lib/close.o lib/unlink.o\
			lib/getpid.o lib/reboot.o lib/shutdown.o\
			lib/fork.o lib/rtc_time.o \
			mm/main.o mm/forkexit.o\
			fs/main.o fs/open.o fs/misc.o fs/read_write.o\
			fs/link.o\
#DASMOUTPUT	= kernel.bin.asm

# All Phony Targets
.PHONY : everything final image clean realclean disasm all buildimg

# Default starting position
everything : $(ORANGESBOOT) $(ORANGESKERNEL)

all : realclean everything

final : all clean

image : final buildimg

clean :
	rm -f $(OBJS)

realclean :
	rm -f $(OBJS) $(ORANGESBOOT) $(ORANGESKERNEL)

#disasm :
#	$(DASM) $(DASMFLAGS) $(ORANGESKERNEL) > $(DASMOUTPUT)

# We assume that "a.img" exists in current folder
buildimg :
	dd if=boot/boot.bin of=a.img bs=512 count=1 conv=notrunc
	sudo mount -o loop a.img /mnt/floppy/
	sudo cp -fv boot/loader.bin /mnt/floppy/
	sudo cp -fv kernel.bin /mnt/floppy
	sudo umount /mnt/floppy

boot/boot.bin : boot/boot.asm boot/include/load.inc boot/include/fat12hdr.inc
	$(ASM) $(ASMBFLAGS) -o $@ $<

boot/loader.bin : boot/loader.asm boot/include/load.inc boot/include/fat12hdr.inc boot/include/pm.inc
	$(ASM) $(ASMBFLAGS) -o $@ $<

$(ORANGESKERNEL) : $(OBJS)
	$(LD) $(LDFLAGS) -o $(ORANGESKERNEL) $(OBJS)

kernel/kernel.o : kernel/kernel.asm
	$(ASM) $(ASMKFLAGS) -o $@ $<

lib/syscall.o : lib/syscall.asm
	$(ASM) $(ASMKFLAGS) -o $@ $<

kernel/start.o: kernel/start.c
	$(CC) $(CFLAGS) -o $@ $<

kernel/main.o: kernel/main.c
	$(CC) $(CFLAGS) -o $@ $<

kernel/clock.o: kernel/clock.c
	$(CC) $(CFLAGS) -o $@ $<

kernel/keyboard.o: kernel/keyboard.c
	$(CC) $(CFLAGS) -o $@ $<

kernel/tty.o: kernel/tty.c
	$(CC) $(CFLAGS) -o $@ $<

kernel/console.o: kernel/console.c
	$(CC) $(CFLAGS) -o $@ $<

kernel/i8259.o: kernel/i8259.c
	$(CC) $(CFLAGS) -o $@ $<

kernel/global.o: kernel/global.c
	$(CC) $(CFLAGS) -o $@ $<

kernel/protect.o: kernel/protect.c
	$(CC) $(CFLAGS) -o $@ $<

kernel/proc.o: kernel/proc.c
	$(CC) $(CFLAGS) -o $@ $<

kernel/command.o: kernel/command.c
	$(CC) $(CFLAGS) -o $@ $<

lib/printf.o: lib/printf.c
	$(CC) $(CFLAGS) -o $@ $<

lib/vsprintf.o: lib/vsprintf.c
	$(CC) $(CFLAGS) -o $@ $<

kernel/systask.o: kernel/systask.c
	$(CC) $(CFLAGS) -o $@ $<

kernel/hd.o: kernel/hd.c
	$(CC) $(CFLAGS) -o $@ $<

lib/klib.o: lib/klib.c
	$(CC) $(CFLAGS) -o $@ $<

lib/misc.o: lib/misc.c
	$(CC) $(CFLAGS) -o $@ $<

lib/kliba.o : lib/kliba.asm
	$(ASM) $(ASMKFLAGS) -o $@ $<

lib/string.o : lib/string.asm
	$(ASM) $(ASMKFLAGS) -o $@ $<

lib/open.o: lib/open.c
	$(CC) $(CFLAGS) -o $@ $<

lib/read.o: lib/read.c
	$(CC) $(CFLAGS) -o $@ $<

lib/write.o: lib/write.c
	$(CC) $(CFLAGS) -o $@ $<

lib/close.o: lib/close.c
	$(CC) $(CFLAGS) -o $@ $<

lib/unlink.o: lib/unlink.c
	$(CC) $(CFLAGS) -o $@ $<

lib/getpid.o: lib/getpid.c
	$(CC) $(CFLAGS) -o $@ $<

lib/reboot.o: lib/reboot.c
	$(CC) $(CFLAGS) -o $@ $<

lib/shutdown.o: lib/shutdown.c
	$(CC) $(CFLAGS) -o $@ $<

lib/fork.o: lib/fork.c
	$(CC) $(CFLAGS) -o $@ $<

lib/rtc_time.o: lib/rtc_time.c
	$(CC) $(CFLAGS) -o $@ $<

mm/main.o: mm/main.c
	$(CC) $(CFLAGS) -o $@ $<

mm/forkexit.o: mm/forkexit.c
	$(CC) $(CFLAGS) -o $@ $<

fs/main.o: fs/main.c
	$(CC) $(CFLAGS) -o $@ $<

fs/open.o: fs/open.c
	$(CC) $(CFLAGS) -o $@ $<

fs/read_write.o: fs/read_write.c
	$(CC) $(CFLAGS) -o $@ $<

fs/link.o: fs/link.c
	$(CC) $(CFLAGS) -o $@ $<
