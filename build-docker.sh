#!/usr/bin/env bash
set -e

# Docker-based ISO build script - works on any Linux system with Docker

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}==>${NC} $1"
}

print_error() {
    echo -e "${RED}Error:${NC} $1" >&2
    exit 1
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}Warning:${NC} $1"
}

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    print_error "Docker daemon is not running. Please start Docker first."
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_step "Building ISO using Docker + Arch Linux container..."
echo ""

# Build the ISO inside Docker
docker run --rm --privileged \
    -v "$SCRIPT_DIR:/workspace:rw" \
    -w /workspace \
    archlinux:latest \
    bash -c '
set -e

echo "==> Initializing Arch Linux container..."
pacman-key --init
pacman-key --populate archlinux

echo "==> Updating system and installing dependencies..."
pacman -Syu --noconfirm
pacman -S --noconfirm archiso git sudo grub

echo "==> Preparing build environment..."
# Copy dotfiles to ISO
mkdir -p archiso/airootfs/root/dotfiles
cp -r dot_config archiso/airootfs/root/dotfiles/ 2>/dev/null || true
cp dot_bashrc archiso/airootfs/root/dotfiles/ 2>/dev/null || true
cp .chezmoi.toml.tmpl archiso/airootfs/root/dotfiles/ 2>/dev/null || true

# Create auto-login service
mkdir -p archiso/airootfs/etc/systemd/system/getty@tty1.service.d
cat > archiso/airootfs/etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I \$TERM
EOF

# Create installer launch script
cat > archiso/airootfs/root/.bash_profile << "EOF"
#!/bin/bash

if [[ -z \$DISPLAY ]] && [[ \$(tty) = /dev/tty1 ]]; then
    clear
    echo "Welcome to Hyprland Minimal Installer"
    echo ""
    echo "Type '\''installer'\'' to start the installation process"
    echo ""
fi

alias installer="/usr/local/bin/installer.sh"
source ~/.bashrc 2>/dev/null || true
EOF

# Set permissions
chmod +x archiso/airootfs/usr/local/bin/installer.sh 2>/dev/null || true
chmod +x archiso/profiledef.sh 2>/dev/null || true

echo "==> Building ISO (this will take a few minutes)..."
START_TIME=$(date +%s)

# Clean previous work
rm -rf work/

# Build with fast compression by default
if [[ -f archiso/profiledef-fast.sh ]]; then
    cp archiso/profiledef-fast.sh archiso/profiledef.sh
fi

mkarchiso -v -w work -o out archiso

END_TIME=$(date +%s)
BUILD_TIME=$((END_TIME - START_TIME))
BUILD_MIN=$((BUILD_TIME / 60))
BUILD_SEC=$((BUILD_TIME % 60))

echo ""
echo "==> ISO build completed in ${BUILD_MIN}m ${BUILD_SEC}s"

# Fix permissions on output (Docker runs as root)
chmod -R 755 out/ 2>/dev/null || true
'

ISO_FILE=$(ls -t "$SCRIPT_DIR/out"/*.iso 2>/dev/null | head -1)

if [[ -f "$ISO_FILE" ]]; then
    echo ""
    print_success "ISO built successfully!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ISO: $ISO_FILE"
    echo "  Size: $(du -h "$ISO_FILE" | cut -f1)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "To test in VM:"
    echo "  qemu-system-x86_64 -enable-kvm -m 4G -boot d -cdrom '$ISO_FILE'"
    echo ""
    echo "Or with virt-manager, select the ISO file when creating a new VM"
    echo ""
else
    print_error "ISO build failed - check output above for errors"
fi