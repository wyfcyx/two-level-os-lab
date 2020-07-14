target := "riscv64imac-unknown-none-elf"
mode := "debug"
build-path := "target/" + target + "/" + mode + "/"
m-firmware-file := build-path + "machine-app-qemu"
m-bin-file := build-path + "machine-firmware.bin"
s-kernel-file := build-path + "supervisor-app"
s-bin-file := build-path + "supervisor-kernel.bin"

objdump := "riscv64-unknown-elf-objdump"
objcopy := "rust-objcopy --binary-architecture=riscv64"
gdb := "riscv64-unknown-elf-gdb"
size := "rust-size"

build:
    @just -f "machine-app-qemu/justfile" build
    @just -f "supervisor-app/justfile" build
    
qemu: build
    @qemu-system-riscv64 \
            -machine virt \
            -nographic \
            -bios none \
            -device loader,file={{m-bin-file}},addr=0x80000000 \
            -device loader,file={{s-bin-file}},addr=0x80200000

run: build qemu

asm: build
    @{{objdump}} -D {{m-firmware-file}} | less

size: build
    @{{size}} -A -x {{m-firmware-file}}

debug: build
    @qemu-system-riscv64 \
            -machine virt \
            -nographic \
            -bios none \
            -device loader,file={{m-bin-file}},addr=0x80000000 \
            -device loader,file={{s-bin-file}},addr=0x80200000 \
            -gdb tcp::1234 -S
            
gdb: 
    @gdb --eval-command="file {{m-firmware-file}}" --eval-command="target remote localhost:1234"