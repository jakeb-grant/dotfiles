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

echo "==> Updating mirrorlist for faster downloads..."
# Use US mirrors for better speed
cat > /etc/pacman.d/mirrorlist << EOF
Server = https://mirrors.kernel.org/archlinux/\$repo/os/\$arch
Server = https://mirror.rackspace.com/archlinux/\$repo/os/\$arch
Server = https://mirrors.mit.edu/archlinux/\$repo/os/\$arch
Server = https://mirror.math.princeton.edu/pub/archlinux/\$repo/os/\$arch
EOF

echo "==> Updating system and installing dependencies..."
pacman -Syu --noconfirm --disable-download-timeout
pacman -S --noconfirm --disable-download-timeout archiso git sudo grub

echo "==> Fetching official archiso releng profile..."
# Copy archiso from the installed package
cp -r /usr/share/archiso/configs/releng /tmp/archiso-profile

echo "==> Applying customizations to releng profile..."
# Copy our package list
cp archiso/packages.x86_64 /tmp/archiso-profile/

# Copy our profiledef.sh (with our branding and settings)
cp archiso/profiledef.sh /tmp/archiso-profile/

# Copy our boot configurations
cp -r archiso/grub/* /tmp/archiso-profile/grub/ 2>/dev/null || true

# Copy our airootfs customizations (merging with releng)
cp -r archiso/airootfs/* /tmp/archiso-profile/airootfs/

# Copy dotfiles to ISO
mkdir -p /tmp/archiso-profile/airootfs/root/dotfiles
cp -r dot_config /tmp/archiso-profile/airootfs/root/dotfiles/ 2>/dev/null || true
cp -r dot_local /tmp/archiso-profile/airootfs/root/dotfiles/ 2>/dev/null || true
cp dot_bashrc /tmp/archiso-profile/airootfs/root/dotfiles/ 2>/dev/null || true
cp .chezmoi.toml.tmpl /tmp/archiso-profile/airootfs/root/dotfiles/ 2>/dev/null || true

# Copy target package list for installer
cp archiso/target-packages.x86_64 /tmp/archiso-profile/airootfs/root/

# Set permissions
chmod +x /tmp/archiso-profile/airootfs/usr/local/bin/installer.sh 2>/dev/null || true
chmod +x /tmp/archiso-profile/profiledef.sh 2>/dev/null || true

echo "==> Building ISO (this will take a few minutes)..."
START_TIME=$(date +%s)

# Clean previous work
rm -rf work/

mkarchiso -v -w work -o out /tmp/archiso-profile

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