#!/usr/bin/env bash
# shellcheck disable=SC2034

# Fast build profile for testing - trades compression for speed

iso_name="hyprland-minimal"
iso_label="HYPR_$(date +%Y%m)"
iso_publisher="Hyprland Minimal <https://github.com/jakeb-grant/dotfiles>"
iso_application="Hyprland Minimal Install ISO"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('uefi.grub')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
# Using gzip for much faster compression (but larger ISO)
airootfs_image_tool_options=('-comp' 'gzip' '-Xcompression-level' '1')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/gshadow"]="0:0:400"
  ["/usr/local/bin/installer.sh"]="0:0:755"
)