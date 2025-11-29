#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="hyprland-minimal"
iso_label="HYPR_$(date +%Y%m)"
iso_publisher="Hyprland Minimal <https://github.com/yourusername/dotfiles>"
iso_application="Hyprland Minimal Install ISO"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('uefi-x64.systemd-boot.esp' 'uefi-x64.systemd-boot.eltorito')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/gshadow"]="0:0:400"
  ["/usr/local/bin/installer.sh"]="0:0:755"
)