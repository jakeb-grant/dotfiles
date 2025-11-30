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

# User input variables (collected upfront)
DISK=""
SWAP_SIZE=""
USE_ENCRYPTION=false
ENCRYPTION_PASSWORD=""
ROOT_PART_ORIG_UUID=""
USERNAME=""
USER_PASSWORD=""
HOSTNAME=""
TIMEZONE=""
GIT_EMAIL=""
GIT_NAME=""
DEPLOY_DOTFILES=false
AUTO_REBOOT=false

# Cleanup on failure
cleanup() {
    if [[ $? -ne 0 ]]; then
        print_error "Installation failed! Cleaning up..."
        if mountpoint -q "$MOUNT_POINT/boot" 2>/dev/null; then
            umount "$MOUNT_POINT/boot" 2>/dev/null || true
        fi
        if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
            umount -R "$MOUNT_POINT" 2>/dev/null || true
        fi
        if [[ -e /dev/mapper/cryptroot ]]; then
            cryptsetup close cryptroot 2>/dev/null || true
        fi
    fi
}
trap cleanup EXIT

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

# Validation functions
validate_timezone() {
    local tz="$1"
    if [[ -f "/usr/share/zoneinfo/$tz" ]]; then
        return 0
    else
        return 1
    fi
}

validate_email() {
    local email="$1"
    if [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

validate_username() {
    local username="$1"
    local reserved_names="root daemon bin sys sync games man lp mail news uucp proxy www-data backup list irc gnats nobody systemd"

    if [[ -z "$username" ]]; then
        return 1
    elif [[ ! "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        return 1
    elif [[ ${#username} -gt 32 ]]; then
        return 1
    elif echo "$reserved_names" | grep -w "$username" &>/dev/null; then
        return 1
    else
        return 0
    fi
}

validate_hostname() {
    local hostname="$1"
    if [[ -z "$hostname" ]]; then
        return 1
    elif [[ ! "$hostname" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$ ]]; then
        return 1
    else
        return 0
    fi
}

validate_swap_size() {
    local size="$1"
    if [[ "$size" =~ ^[0-9]+[GMgm]$ ]]; then
        return 0
    else
        return 1
    fi
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

# Collect all user input upfront
collect_all_user_input() {
    print_step "Configuration - Please answer the following questions"
    echo ""

    # Network setup
    print_step "Network Configuration"
    local connection_type=$(gum choose --header "Select connection type:" "Ethernet" "WiFi" "Skip (already connected)")

    case "$connection_type" in
        "Ethernet")
            print_step "Configuring ethernet..."
            if ! systemctl start dhcpcd; then
                print_error "Failed to start dhcpcd"
                exit 1
            fi
            sleep 3
            ;;
        "WiFi")
            print_step "Configuring WiFi..."
            if ! systemctl start iwd; then
                print_error "Failed to start iwd"
                exit 1
            fi
            sleep 2

            # Detect WiFi interface
            local wifi_iface=$(iw dev | awk '$1=="Interface"{print $2; exit}')
            if [[ -z "$wifi_iface" ]]; then
                print_error "No wireless interface found"
                exit 1
            fi
            print_step "Using WiFi interface: $wifi_iface"

            # Scan for networks
            iwctl station "$wifi_iface" scan
            sleep 3

            # Get available networks
            local networks=$(iwctl station "$wifi_iface" get-networks | tail -n +5 | head -n -1 | awk '{print $1}')

            if [[ -z "$networks" ]]; then
                print_error "No WiFi networks found"
                exit 1
            fi

            local selected_network=$(echo "$networks" | gum choose --header "Select WiFi network:")
            local wifi_password=$(gum input --password --placeholder "Enter WiFi password")

            iwctl --passphrase="$wifi_password" station "$wifi_iface" connect "$selected_network"
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
    if ! reflector --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist; then
        print_warning "Failed to update mirror list, using default mirrors"
    else
        print_success "Mirror list updated"
    fi

    echo ""

    # Disk selection
    print_step "Disk Selection"
    local disks=$(lsblk -dno NAME,SIZE,MODEL | grep -E '^(sd|nvme|vd)' | awk '{print $1 " - " $2 " " $3}')

    if [[ -z "$disks" ]]; then
        print_error "No suitable disks found"
        exit 1
    fi

    local selected_disk=$(echo "$disks" | gum choose --header "Select installation disk (ALL DATA WILL BE ERASED):")
    DISK="/dev/$(echo "$selected_disk" | awk '{print $1}')"

    # Confirm disk selection
    gum confirm --affirmative "Yes, wipe $DISK" --negative "No, cancel" "Are you sure you want to use $DISK? This will ERASE ALL DATA!" || exit 1

    echo ""

    # Swap configuration
    print_step "Swap Configuration"
    local total_ram=$(free -m | awk '/^Mem:/{print int($2/1024)}')
    if [[ $total_ram -eq 0 ]]; then
        total_ram=1  # Minimum 1GB
    fi

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
            while true; do
                SWAP_SIZE=$(gum input --placeholder "Enter swap size (e.g., 4G, 512M)")
                if validate_swap_size "$SWAP_SIZE"; then
                    break
                else
                    print_error "Invalid format. Use number followed by G or M (e.g., 4G, 512M)"
                fi
            done
            ;;
        "No swap")
            SWAP_SIZE="0"
            ;;
    esac

    echo ""

    # User configuration (collected first so we can offer to reuse password for encryption)
    print_step "User Configuration"

    while true; do
        USERNAME=$(gum input --placeholder "Enter username")
        if validate_username "$USERNAME"; then
            break
        else
            print_error "Invalid username. Use lowercase letters, numbers, dash, underscore (max 32 chars)"
            gum style --foreground 3 "Cannot use reserved names like: root, daemon, bin, sys, etc."
        fi
    done

    USER_PASSWORD=$(gum input --password --placeholder "Enter password for $USERNAME")
    local user_password_confirm=$(gum input --password --placeholder "Confirm password")

    if [[ "$USER_PASSWORD" != "$user_password_confirm" ]]; then
        print_error "Passwords do not match"
        exit 1
    fi

    if [[ -z "$USER_PASSWORD" ]]; then
        print_error "Password cannot be empty"
        exit 1
    fi

    while true; do
        HOSTNAME=$(gum input --placeholder "Enter hostname" --value "${USERNAME}-hypr")
        if validate_hostname "$HOSTNAME"; then
            break
        else
            print_error "Invalid hostname. Use lowercase letters, numbers, and dashes"
        fi
    done

    echo ""

    # Encryption
    print_step "Encryption Configuration"
    if gum confirm "Do you want to encrypt the root partition?"; then
        USE_ENCRYPTION=true

        # Offer to use the same password as user password
        if gum confirm "Use the same password as your user account for disk encryption?"; then
            ENCRYPTION_PASSWORD="$USER_PASSWORD"
            print_success "Using user password for disk encryption"
        else
            ENCRYPTION_PASSWORD=$(gum input --password --placeholder "Enter disk encryption password")
            local encryption_confirm=$(gum input --password --placeholder "Confirm encryption password")

            if [[ "$ENCRYPTION_PASSWORD" != "$encryption_confirm" ]]; then
                print_error "Passwords do not match"
                exit 1
            fi

            if [[ -z "$ENCRYPTION_PASSWORD" ]]; then
                print_error "Password cannot be empty"
                exit 1
            fi
        fi
    else
        USE_ENCRYPTION=false
    fi

    echo ""

    # Timezone
    print_step "Timezone Configuration"
    while true; do
        TIMEZONE=$(gum input --placeholder "Enter timezone (e.g., America/New_York, Europe/London, UTC)")

        if validate_timezone "$TIMEZONE"; then
            print_success "Timezone validated: $TIMEZONE"
            break
        else
            print_error "Invalid timezone. Please enter a valid timezone path."
            gum style --foreground 3 "Examples: America/New_York, Europe/London, Asia/Tokyo, UTC"
        fi
    done

    echo ""

    # Git configuration
    print_step "Git Configuration"
    while true; do
        GIT_EMAIL=$(gum input --placeholder "Git email address (e.g., you@example.com)")

        if validate_email "$GIT_EMAIL"; then
            break
        else
            print_error "Invalid email format. Please enter a valid email address."
        fi
    done

    while true; do
        GIT_NAME=$(gum input --placeholder "Git full name (e.g., John Doe)")
        if [[ -n "$GIT_NAME" ]]; then
            break
        else
            print_error "Git name cannot be empty"
        fi
    done

    echo ""

    # Dotfiles
    print_step "Dotfiles Configuration"
    if gum confirm "Deploy dotfiles from repository ($DOTFILES_REPO)?"; then
        DEPLOY_DOTFILES=true
    else
        DEPLOY_DOTFILES=false
    fi

    echo ""

    # Auto-reboot
    print_step "Installation Completion"
    if gum confirm "Automatically reboot after installation completes?"; then
        AUTO_REBOOT=true
    else
        AUTO_REBOOT=false
    fi

    echo ""
    print_success "All configuration collected!"
}

# Show installation summary and confirm
show_installation_summary() {
    clear

    gum style \
        --foreground 212 --border-foreground 212 --border double \
        --align center --width 60 --margin "1 2" --padding "2 4" \
        "Installation Summary"

    echo ""

    local encryption_status="No"
    if [[ "$USE_ENCRYPTION" == true ]]; then
        encryption_status="Yes"
    fi

    local dotfiles_status="Copy from ISO"
    if [[ "$DEPLOY_DOTFILES" == true ]]; then
        dotfiles_status="Deploy from repository"
    fi

    local reboot_status="No (manual reboot)"
    if [[ "$AUTO_REBOOT" == true ]]; then
        reboot_status="Yes (automatic)"
    fi

    gum style --border normal --border-foreground 6 --padding "1 2" --width 60 "
╔══════════════════════════════════════════════════════════╗
║                 Configuration Overview                   ║
╠══════════════════════════════════════════════════════════╣
║ Disk:           $DISK
║ Swap:           $SWAP_SIZE
║ Encryption:     $encryption_status
║ Username:       $USERNAME
║ Hostname:       $HOSTNAME
║ Timezone:       $TIMEZONE
║ Git Email:      $GIT_EMAIL
║ Git Name:       $GIT_NAME
║ Dotfiles:       $dotfiles_status
║ Auto-reboot:    $reboot_status
╚══════════════════════════════════════════════════════════╝
"

    echo ""
    gum confirm --affirmative "Begin Installation" --negative "Cancel" "Proceed with installation using the above configuration?" || {
        print_warning "Installation cancelled by user"
        exit 0
    }

    echo ""
    print_success "Starting installation..."
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

    # Wait for partitions to appear (max 10 seconds)
    print_step "Waiting for partitions to be recognized..."
    for i in {1..10}; do
        if [[ -e "$EFI_PART" && -e "$ROOT_PART" ]]; then
            break
        fi
        sleep 1
    done

    # Verify partitions exist
    if [[ ! -e "$EFI_PART" ]]; then
        print_error "EFI partition not found: $EFI_PART"
        exit 1
    fi

    if [[ ! -e "$ROOT_PART" ]]; then
        print_error "Root partition not found: $ROOT_PART"
        exit 1
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
        # Save original partition path and UUID for GRUB cryptdevice config
        ROOT_PART_ORIG="$ROOT_PART"
        echo -n "$ENCRYPTION_PASSWORD" | cryptsetup -q luksFormat "$ROOT_PART" -
        echo -n "$ENCRYPTION_PASSWORD" | cryptsetup open "$ROOT_PART" cryptroot -
        # Capture UUID before changing ROOT_PART variable
        ROOT_PART_ORIG_UUID=$(blkid -s UUID -o value "$ROOT_PART_ORIG")
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

# Configure system
configure_system() {
    print_step "Configuring system"

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

# Configure git for user
mkdir -p /home/$USERNAME
cat > /home/$USERNAME/.gitconfig << GITEOF
[user]
	email = $GIT_EMAIL
	name = $GIT_NAME
GITEOF
chown $USERNAME:$USERNAME /home/$USERNAME/.gitconfig

# Install bootloader
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

# Configure GRUB for encryption if needed
if [[ "$USE_ENCRYPTION" == true ]]; then
    sed -i "s|GRUB_CMDLINE_LINUX=\"\"|GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=$ROOT_PART_ORIG_UUID:cryptroot root=/dev/mapper/cryptroot\"|" /etc/default/grub

    # Add encrypt hook to mkinitcpio
    sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect modconf block encrypt filesystems keyboard fsck)/' /etc/mkinitcpio.conf
    mkinitcpio -P
fi

grub-mkconfig -o /boot/grub/grub.cfg

# Enable services
systemctl enable NetworkManager
systemctl enable fstrim.timer

# Configure PAM for gnome-keyring auto-unlock on login
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

    # Check if package file exists
    if [[ ! -f /root/target-packages.x86_64 ]]; then
        print_error "Package list file not found: /root/target-packages.x86_64"
        exit 1
    fi

    # Read packages from target-packages.x86_64, filtering comments and empty lines
    local packages=""
    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        packages="$packages $line"
    done < /root/target-packages.x86_64

    # Verify we have packages to install
    if [[ -z "$packages" ]]; then
        print_error "No packages found in target-packages.x86_64"
        exit 1
    fi

    arch-chroot "$MOUNT_POINT" pacman -S --noconfirm $packages

    # Install GPU drivers after base Hyprland packages
    install_gpu_drivers

    print_success "Hyprland environment installed"
}

# Setup dotfiles
setup_dotfiles() {
    print_step "Setting up dotfiles with chezmoi"

    if [[ "$DEPLOY_DOTFILES" == true ]]; then
        print_warning "Network not available during installation - using ISO dotfiles"
        print_step "After first boot, run: chezmoi init --apply $DOTFILES_REPO"
        DEPLOY_DOTFILES=false
    fi

    if [[ "$DEPLOY_DOTFILES" == false ]]; then
        print_step "Copying dotfiles from ISO"

        # Check if dotfiles directory exists
        if [[ ! -d /root/dotfiles ]]; then
            print_warning "Dotfiles directory not found at /root/dotfiles, skipping dotfiles setup"
            return 0
        fi

        # Copy dotfiles from ISO if they exist
        if [[ -d /root/dotfiles/dot_config ]]; then
            cp -r /root/dotfiles/dot_config "$MOUNT_POINT/home/$USERNAME/.config"
        fi

        if [[ -f /root/dotfiles/dot_bashrc ]]; then
            cp /root/dotfiles/dot_bashrc "$MOUNT_POINT/home/$USERNAME/.bashrc"
        fi

        # Fix permissions
        arch-chroot "$MOUNT_POINT" chown -R "$USERNAME:$USERNAME" "/home/$USERNAME"

        print_success "Dotfiles copied from ISO"
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

    # Collect all user input upfront
    collect_all_user_input

    # Show summary and confirm
    show_installation_summary

    # From here on, no more user input required
    partition_disk
    format_partitions
    mount_partitions
    install_base
    generate_fstab
    configure_system
    install_hyprland
    setup_dotfiles

    # Unmount
    umount -R "$MOUNT_POINT"

    if [[ "$USE_ENCRYPTION" == true ]]; then
        cryptsetup close cryptroot
    fi

    # Clear sensitive variables
    unset ENCRYPTION_PASSWORD
    unset USER_PASSWORD

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

    # Auto-reboot if requested
    if [[ "$AUTO_REBOOT" == true ]]; then
        print_step "Rebooting in 5 seconds..."
        sleep 5
        reboot
    else
        gum style --foreground 3 "You can now reboot into your new system!"
    fi
}

# Run main function
main "$@"
