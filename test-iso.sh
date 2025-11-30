#!/usr/bin/env bash

# Quick ISO test script - boots the ISO in QEMU with UEFI

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISO_FILE=$(ls -t "$SCRIPT_DIR/out"/*.iso 2>/dev/null | head -1)

if [[ ! -f "$ISO_FILE" ]]; then
    echo "Error: No ISO found in out/ directory"
    echo "Run ./build-docker.sh first to build the ISO"
    exit 1
fi

echo "Testing ISO: $ISO_FILE"
echo "Press Ctrl+Alt+G to release mouse/keyboard"
echo ""

# Create NVRAM file if it doesn't exist
NVRAM_FILE="$SCRIPT_DIR/.nvram-test.fd"
if [[ ! -f "$NVRAM_FILE" ]]; then
    cp /run/libvirt/nix-ovmf/edk2-i386-vars.fd "$NVRAM_FILE" 2>/dev/null || dd if=/dev/zero of="$NVRAM_FILE" bs=1M count=1 2>/dev/null
fi
# Ensure it's writable
chmod 644 "$NVRAM_FILE"

# Create virtual disk for installation testing
DISK_FILE="$SCRIPT_DIR/test-disk.qcow2"
if [[ ! -f "$DISK_FILE" ]]; then
    echo "Creating 40GB virtual disk for installation testing..."
    qemu-img create -f qcow2 "$DISK_FILE" 40G
fi

/run/libvirt/nix-emulators/qemu-system-x86_64 \
  -enable-kvm \
  -m 5G \
  -cpu host \
  -smp 4 \
  -drive if=pflash,format=raw,readonly=on,file=/run/libvirt/nix-ovmf/edk2-x86_64-code.fd \
  -drive if=pflash,format=raw,file="$NVRAM_FILE" \
  -drive file="$DISK_FILE",format=qcow2,if=virtio \
  -cdrom "$ISO_FILE" \
  -boot d \
  -vga virtio \
  -display gtk,gl=on \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -device virtio-net-pci,netdev=net0

echo ""
echo "SSH into VM with: ssh -p 2222 root@localhost"
echo "(No password required)"
