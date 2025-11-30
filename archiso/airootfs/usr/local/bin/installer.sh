#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration variables
MOUNT_POINT="/mnt"
DOTFILES_REPO="https://github.com/jakeb-grant/dotfiles.git"

# Functions
print_step() {
    echo -e "${BLUE}==>${NC} $1"
}

print_error() {
    echo -e "${RED}Error:${NC} $1" >&2
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}Warning:${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

# Check UEFI mode
check_uefi() {
    if [[ ! -d /sys/firmware/efi/efivars ]]; then
        print_error "System is not booted in UEFI mode. This installer only supports UEFI systems."
        exit 1
    fi
    print_success "System booted in UEFI mode"
}

# Network setup
setup_network() {
    print_step "Setting up network connection"

    local connection_type=$(gum choose --header "Select connection type:" "Ethernet" "WiFi" "Skip (already connected)")

    case "$connection_type" in
        "Ethernet")
            print_step "Configuring ethernet..."
            systemctl start dhcpcd
            sleep 3
            ;;
        "WiFi")
            print_step "Configuring WiFi..."
            systemctl start iwd
            sleep 2

            # Scan for networks
            iwctl station wlan0 scan
            sleep 3

            # Get available networks
            local networks=$(iwctl station wlan0 get-networks | tail -n +5 | head -n -1 | awk '{print $1}')

            if [[ -z "$networks" ]]; then
                print_error "No WiFi networks found"
                exit 1
            fi

            local selected_network=$(echo "$networks" | gum choose --header "Select WiFi network:")
            local wifi_password=$(gum input --password --placeholder "Enter WiFi password")

            iwctl --passphrase="$wifi_password" station wlan0 connect "$selected_network"
            sleep 5
            ;;
        "Skip (already connected)")
            print_step "Skipping network setup"
            ;;
    esac

    # Test connection
    print_step "Testing network connection..."
    if ping -c 1 archlinux.org &>/dev/null; then
        print_success "Network connection established"
    else
        print_error "No network connection. Please check your settings."
        exit 1
    fi

    # Update mirror list
    print_step "Updating mirror list..."
    reflector --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
    print_success "Mirror list updated"
}

# Disk selection and partitioning
select_disk() {
    print_step "Disk Selection"

    # Get available disks
    local disks=$(lsblk -dno NAME,SIZE,MODEL | grep -E '^(sd|nvme|vd)' | awk '{print $1 " - " $2 " " $3}')

    if [[ -z "$disks" ]]; then
        print_error "No suitable disks found"
        exit 1
    fi

    local selected_disk=$(echo "$disks" | gum choose --header "Select installation disk (ALL DATA WILL BE ERASED):")
    DISK="/dev/$(echo "$selected_disk" | awk '{print $1}')"

    # Confirm disk selection
    gum confirm --affirmative "Yes, wipe $DISK" --negative "No, cancel" "Are you sure you want to use $DISK? This will ERASE ALL DATA!" || exit 1

    print_success "Selected disk: $DISK"
}

# Get swap size
get_swap_size() {
    print_step "Swap Configuration"

    local total_ram=$(free -g | awk '/^Mem:/{print $2}')
    local default_swap=$((total_ram < 8 ? total_ram * 2 : total_ram))

    local swap_choice=$(gum choose --header "Select swap size:" \
        "Same as RAM (${total_ram}G)" \
        "Double RAM ($((total_ram * 2))G)" \
        "Half RAM ($((total_ram / 2))G)" \
        "Custom" \
        "No swap")

    case "$swap_choice" in
        "Same as RAM"*)
            SWAP_SIZE="${total_ram}G"
            ;;
        "Double RAM"*)
            SWAP_SIZE="$((total_ram * 2))G"
            ;;
        "Half RAM"*)
            SWAP_SIZE="$((total_ram / 2))G"
            ;;
        "Custom")
            SWAP_SIZE=$(gum input --placeholder "Enter swap size (e.g., 4G, 8G)")
            ;;
        "No swap")
            SWAP_SIZE="0"
            ;;
    esac

    print_success "Swap size: $SWAP_SIZE"
}

# Encryption setup
setup_encryption() {
    print_step "Encryption Configuration"

    if gum confirm "Do you want to encrypt the root partition?"; then
        USE_ENCRYPTION=true
        ENCRYPTION_PASSWORD=$(gum input --password --placeholder "Enter encryption password")
        ENCRYPTION_PASSWORD_CONFIRM=$(gum input --password --placeholder "Confirm encryption password")

        if [[ "$ENCRYPTION_PASSWORD" != "$ENCRYPTION_PASSWORD_CONFIRM" ]]; then
            print_error "Passwords do not match"
            exit 1
        fi

        if [[ -z "$ENCRYPTION_PASSWORD" ]]; then
            print_error "Password cannot be empty"
            exit 1
        fi

        print_success "Encryption will be enabled"
    else
        USE_ENCRYPTION=false
        print_success "Proceeding without encryption"
    fi
}

# Partition disk
partition_disk() {
    print_step "Partitioning disk $DISK"

    # Wipe disk
    wipefs -af "$DISK"
    sgdisk -Z "$DISK"

    # Create partitions
    sgdisk -n 0:0:+1G -t 0:ef00 -c 0:"EFI" "$DISK"

    if [[ "$SWAP_SIZE" != "0" ]]; then
        sgdisk -n 0:0:+${SWAP_SIZE} -t 0:8200 -c 0:"SWAP" "$DISK"
    fi

    sgdisk -n 0:0:0 -t 0:8300 -c 0:"ROOT" "$DISK"

    # Inform kernel of changes
    partprobe "$DISK"
    sleep 2

    # Set partition variables
    if [[ "$DISK" =~ nvme ]]; then
        EFI_PART="${DISK}p1"
        if [[ "$SWAP_SIZE" != "0" ]]; then
            SWAP_PART="${DISK}p2"
            ROOT_PART="${DISK}p3"
        else
            ROOT_PART="${DISK}p2"
        fi
    else
        EFI_PART="${DISK}1"
        if [[ "$SWAP_SIZE" != "0" ]]; then
            SWAP_PART="${DISK}2"
            ROOT_PART="${DISK}3"
        else
            ROOT_PART="${DISK}2"
        fi
    fi

    print_success "Disk partitioned successfully"
}

# Format partitions
format_partitions() {
    print_step "Formatting partitions"

    # Format EFI partition
    mkfs.fat -F32 "$EFI_PART"

    # Setup encryption if enabled
    if [[ "$USE_ENCRYPTION" == true ]]; then
        print_step "Setting up LUKS encryption"
        # Save original partition path for GRUB cryptdevice config
        ROOT_PART_ORIG="$ROOT_PART"
        echo -n "$ENCRYPTION_PASSWORD" | cryptsetup -q luksFormat "$ROOT_PART" -
        echo -n "$ENCRYPTION_PASSWORD" | cryptsetup open "$ROOT_PART" cryptroot -
        ROOT_PART="/dev/mapper/cryptroot"
    fi

    # Format root partition
    mkfs.ext4 "$ROOT_PART"

    # Format swap if it exists
    if [[ -n "$SWAP_PART" ]]; then
        mkswap "$SWAP_PART"
        swapon "$SWAP_PART"
    fi

    print_success "Partitions formatted successfully"
}

# Mount partitions
mount_partitions() {
    print_step "Mounting partitions"

    mount "$ROOT_PART" "$MOUNT_POINT"
    mkdir -p "$MOUNT_POINT/boot"
    mount "$EFI_PART" "$MOUNT_POINT/boot"

    print_success "Partitions mounted successfully"
}

# Install base system
install_base() {
    print_step "Installing base system"

    # Detect CPU manufacturer
    local cpu_ucode=""
    if grep -q "GenuineIntel" /proc/cpuinfo; then
        print_step "Intel CPU detected"
        cpu_ucode="intel-ucode"
    elif grep -q "AuthenticAMD" /proc/cpuinfo; then
        print_step "AMD CPU detected"
        cpu_ucode="amd-ucode"
    fi

    pacstrap "$MOUNT_POINT" base base-devel linux linux-firmware linux-headers \
        networkmanager grub efibootmgr \
        git zed sudo bash-completion \
        $cpu_ucode

    print_success "Base system installed"
}

# Generate fstab
generate_fstab() {
    print_step "Generating fstab"
    genfstab -U "$MOUNT_POINT" >> "$MOUNT_POINT/etc/fstab"
    print_success "fstab generated"
}

# User setup
setup_user() {
    print_step "User Configuration"

    USERNAME=$(gum input --placeholder "Enter username")
    USER_PASSWORD=$(gum input --password --placeholder "Enter password for $USERNAME")
    USER_PASSWORD_CONFIRM=$(gum input --password --placeholder "Confirm password")

    if [[ "$USER_PASSWORD" != "$USER_PASSWORD_CONFIRM" ]]; then
        print_error "Passwords do not match"
        exit 1
    fi

    if [[ -z "$USER_PASSWORD" ]]; then
        print_error "Password cannot be empty"
        exit 1
    fi

    HOSTNAME=$(gum input --placeholder "Enter hostname" --value "${USERNAME}-hypr")

    print_success "User configuration set"
}

# Configure system
configure_system() {
    print_step "Configuring system"

    # Select timezone interactively before creating chroot script
    print_step "Select your timezone"
    TIMEZONE=$(tzselect)

    # Create configuration script
    cat > "$MOUNT_POINT/configure.sh" << EOCHROOT
#!/bin/bash
set -e

# Set timezone
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Localization
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Hostname
echo "$HOSTNAME" > /etc/hostname
cat > /etc/hosts << EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF

# Create user
useradd -m -G wheel -s /bin/bash "$USERNAME"
echo "$USERNAME:$USER_PASSWORD" | chpasswd

# Configure sudo
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Install bootloader
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

# Configure GRUB for encryption if needed
if [[ "$USE_ENCRYPTION" == true ]]; then
    ROOTUUID=\$(blkid -s UUID -o value $ROOT_PART_ORIG)
    sed -i "s|GRUB_CMDLINE_LINUX=\"\"|GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=\$ROOTUUID:cryptroot root=/dev/mapper/cryptroot\"|" /etc/default/grub

    # Add encrypt hook to mkinitcpio
    sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect modconf block encrypt filesystems keyboard fsck)/' /etc/mkinitcpio.conf
    mkinitcpio -P
fi

grub-mkconfig -o /boot/grub/grub.cfg

# Enable services
systemctl enable NetworkManager
systemctl enable fstrim.timer

# Configure PAM for gnome-keyring auto-unlock on login
# This allows the keyring to be unlocked automatically with user password
echo "auth       optional     pam_gnome_keyring.so" >> /etc/pam.d/login
echo "session    optional     pam_gnome_keyring.so auto_start" >> /etc/pam.d/login

# Set root password (same as user for now, should be changed)
echo "root:$USER_PASSWORD" | chpasswd

EOCHROOT

    chmod +x "$MOUNT_POINT/configure.sh"
    arch-chroot "$MOUNT_POINT" /configure.sh
    rm "$MOUNT_POINT/configure.sh"

    print_success "System configured"
}

# Detect and install GPU drivers
install_gpu_drivers() {
    print_step "Detecting GPU and installing drivers"

    local gpu_packages=""

    # Detect NVIDIA
    if lspci | grep -i 'nvidia' &>/dev/null; then
        print_step "NVIDIA GPU detected"

        # Determine which NVIDIA driver to use
        if lspci | grep -i 'nvidia' | grep -q -E "RTX [2-9][0-9]|GTX 16"; then
            print_step "Modern NVIDIA GPU - using nvidia-open-dkms"
            gpu_packages="nvidia-open-dkms nvidia-utils lib32-nvidia-utils egl-wayland libva-nvidia-driver"
        else
            print_step "Older NVIDIA GPU - using nvidia-dkms"
            gpu_packages="nvidia-dkms nvidia-utils lib32-nvidia-utils egl-wayland libva-nvidia-driver"
        fi

        # Install NVIDIA drivers
        arch-chroot "$MOUNT_POINT" pacman -S --noconfirm $gpu_packages

        # Configure NVIDIA for early KMS
        echo "options nvidia_drm modeset=1" > "$MOUNT_POINT/etc/modprobe.d/nvidia.conf"

        # Add NVIDIA modules to mkinitcpio
        arch-chroot "$MOUNT_POINT" bash -c "
            sed -i -E 's/ nvidia_drm//g; s/ nvidia_uvm//g; s/ nvidia_modeset//g; s/ nvidia//g;' /etc/mkinitcpio.conf
            sed -i -E 's/^(MODULES=\\()/\\1nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf
            sed -i -E 's/  +/ /g' /etc/mkinitcpio.conf
            mkinitcpio -P
        "

        print_success "NVIDIA drivers installed and configured"

    # Detect AMD
    elif lspci | grep -E 'VGA|3D' | grep -i 'amd\|radeon' &>/dev/null; then
        print_step "AMD GPU detected"
        gpu_packages="mesa vulkan-radeon libva-mesa-driver mesa-vdpau"
        arch-chroot "$MOUNT_POINT" pacman -S --noconfirm $gpu_packages
        print_success "AMD drivers installed"

    # Detect Intel
    elif lspci | grep -iE 'VGA|3D|Display' | grep -i 'intel' &>/dev/null; then
        print_step "Intel GPU detected"

        # Get Intel GPU model
        local intel_gpu=$(lspci | grep -iE 'VGA|3D|Display' | grep -i 'intel')
        local intel_gpu_lower="${intel_gpu,,}"

        # Determine which VA-API driver to use
        local va_driver=""
        if [[ "$intel_gpu_lower" =~ "hd graphics"|"xe"|"iris" ]]; then
            print_step "Modern Intel GPU detected (HD Graphics/Xe/Iris) - using intel-media-driver"
            va_driver="intel-media-driver"
        elif [[ "$intel_gpu_lower" =~ "gma" ]]; then
            print_step "Older Intel GPU detected (GMA) - using libva-intel-driver"
            va_driver="libva-intel-driver"
        else
            print_step "Intel GPU detected - using intel-media-driver (default)"
            va_driver="intel-media-driver"
        fi

        gpu_packages="mesa vulkan-intel $va_driver"
        arch-chroot "$MOUNT_POINT" pacman -S --noconfirm $gpu_packages
        print_success "Intel drivers installed"

    else
        print_warning "No discrete GPU detected, using mesa (software rendering)"
        arch-chroot "$MOUNT_POINT" pacman -S --noconfirm mesa
    fi
}

# Install Hyprland environment
install_hyprland() {
    print_step "Installing Hyprland environment"

    # Read packages from target-packages.x86_64, filtering comments and empty lines
    local packages=""
    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        packages="$packages $line"
    done < /root/target-packages.x86_64

    arch-chroot "$MOUNT_POINT" pacman -S --noconfirm $packages

    # Install GPU drivers after base Hyprland packages
    install_gpu_drivers

    print_success "Hyprland environment installed"
}

# Setup dotfiles
setup_dotfiles() {
    print_step "Setting up dotfiles with chezmoi"

    if gum confirm "Do you want to deploy the dotfiles from the repository?"; then
        arch-chroot "$MOUNT_POINT" su - "$USERNAME" -c "
            chezmoi init --apply $DOTFILES_REPO
        "
        print_success "Dotfiles deployed"
    else
        print_step "Copying dotfiles to user home"

        # Copy dotfiles from ISO
        cp -r /root/dotfiles/dot_config "$MOUNT_POINT/home/$USERNAME/.config"
        cp /root/dotfiles/dot_bashrc "$MOUNT_POINT/home/$USERNAME/.bashrc"

        # Fix permissions
        arch-chroot "$MOUNT_POINT" chown -R "$USERNAME:$USERNAME" "/home/$USERNAME"

        print_success "Dotfiles copied"
    fi
}

# Main installation flow
main() {
    clear
    gum style \
        --foreground 212 --border-foreground 212 --border double \
        --align center --width 50 --margin "1 2" --padding "2 4" \
        'Hyprland Minimal Installer'

    echo ""
    gum style --foreground 3 "This installer will guide you through setting up a minimal Hyprland system."
    echo ""

    check_root
    check_uefi
    setup_network
    select_disk
    get_swap_size
    setup_encryption
    setup_user

    gum spin --spinner dot --title "Partitioning disk..." -- sleep 2
    partition_disk

    gum spin --spinner dot --title "Formatting partitions..." -- sleep 2
    format_partitions

    mount_partitions

    gum spin --spinner dot --title "Installing base system (this may take a while)..." -- sleep 2
    install_base

    generate_fstab

    gum spin --spinner dot --title "Configuring system..." -- sleep 2
    configure_system

    gum spin --spinner dot --title "Installing Hyprland environment..." -- sleep 2
    install_hyprland

    setup_dotfiles

    # Unmount
    umount -R "$MOUNT_POINT"

    if [[ "$USE_ENCRYPTION" == true ]]; then
        cryptsetup close cryptroot
    fi

    gum style \
        --foreground 10 --border-foreground 10 --border double \
        --align center --width 50 --margin "1 2" --padding "2 4" \
        'Installation Complete!'

    echo ""
    print_success "System installed successfully!"
    print_success "Username: $USERNAME"
    print_success "Hostname: $HOSTNAME"
    if [[ "$USE_ENCRYPTION" == true ]]; then
        print_warning "Root partition is encrypted"
    fi
    echo ""

    if gum confirm "Do you want to reboot now?"; then
        reboot
    fi
}

# Run main function
main "$@"