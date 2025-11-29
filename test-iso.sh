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

/run/libvirt/nix-emulators/qemu-system-x86_64 \
  -enable-kvm \
  -m 5G \
  -cpu host \
  -smp 4 \
  -drive if=pflash,format=raw,readonly=on,file=/run/libvirt/nix-ovmf/edk2-x86_64-code.fd \
  -drive if=pflash,format=raw,file=/tmp/nvram.fd \
  -cdrom "$ISO_FILE" \
  -boot d \
  -vga virtio \
  -display gtk,gl=on
