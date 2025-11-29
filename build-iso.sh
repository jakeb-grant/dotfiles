#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
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

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root"
fi

# Check for required tools
if ! command -v mkarchiso &> /dev/null; then
    print_error "mkarchiso not found. Please install archiso package"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_DIR="$SCRIPT_DIR/archiso"
WORK_DIR="$SCRIPT_DIR/work"
OUT_DIR="$SCRIPT_DIR/out"

# Clean previous builds
if [[ -d "$WORK_DIR" ]]; then
    print_step "Cleaning previous work directory"
    rm -rf "$WORK_DIR"
fi

# Copy dotfiles to the ISO
print_step "Copying dotfiles to ISO filesystem"
mkdir -p "$PROFILE_DIR/airootfs/root/dotfiles"
cp -r "$SCRIPT_DIR/dot_config" "$PROFILE_DIR/airootfs/root/dotfiles/"
cp "$SCRIPT_DIR/dot_bashrc" "$PROFILE_DIR/airootfs/root/dotfiles/"
cp "$SCRIPT_DIR/.chezmoi.toml.tmpl" "$PROFILE_DIR/airootfs/root/dotfiles/"

# Copy target package list for installer
cp "$PROFILE_DIR/target-packages.x86_64" "$PROFILE_DIR/airootfs/root/"

# Build the ISO
print_step "Building ISO (this will take some time)..."
mkarchiso -v -w "$WORK_DIR" -o "$OUT_DIR" "$PROFILE_DIR"

ISO_FILE=$(ls -t "$OUT_DIR"/*.iso | head -1)
if [[ -f "$ISO_FILE" ]]; then
    print_success "ISO built successfully: $ISO_FILE"
    print_success "Size: $(du -h "$ISO_FILE" | cut -f1)"
else
    print_error "ISO build failed"
fi