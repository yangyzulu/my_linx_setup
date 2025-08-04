#!/bin/bash

# Arch Linux Basic Setup Script
# This script automates the basic setup of an Arch Linux system with useful packages,
# development tools, zsh with Oh My Zsh, Neovim with LazyVim, and system snapshots.
#
# Prerequisites:
# - Run as root (the script will check this)
# - Arch Linux system with Btrfs filesystem
# - Not run in a chroot environment
# - Internet connection for package downloads
#
# Usage: sudo ./arch_basic_setup.sh
#
# What this script does:
# 1. Updates system and installs base development tools
# 2. Installs yay AUR helper
# 3. Installs additional useful packages
# 4. Configures Btrfs performance optimizations
# 5. Sets up system snapshots with Timeshift
# 6. Configures GRUB-BTRFS for snapshot booting
# 7. Installs automatic snapshot creation
# 8. Sets up Zsh with Oh My Zsh
# 9. Configures Neovim with LazyVim
# 10. Sets up useful shell aliases

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_info() {
    echo -e "[ℹ] $1"
}

# Install basic packages for Arch Linux setup

# Determine the actual user and home directory (since script runs as root)
if [ "$SUDO_USER" ]; then
    ACTUAL_USER="$SUDO_USER"
    ACTUAL_HOME=$(eval echo "~$SUDO_USER")
    ACTUAL_UID=$(id -u "$SUDO_USER")
    ACTUAL_GID=$(id -g "$SUDO_USER")
else
    ACTUAL_USER="$USER"
    ACTUAL_HOME="$HOME"
    ACTUAL_UID=$(id -u)
    ACTUAL_GID=$(id -g)
fi

echo "Script running as: $(whoami)"
echo "Target user: $ACTUAL_USER"
echo "Target home directory: $ACTUAL_HOME"
echo ""

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    print_error "This script must be run as root. Please use sudo."
    exit 1
fi

# Check if the script is run on Arch Linux
if [ ! -f /etc/arch-release ]; then
    print_error "This script is intended for Arch Linux only."
    exit 1
fi

# Check if the script is run on a Btrfs filesystem
if ! mount | grep -q "type btrfs"; then
    print_error "This script is intended for systems with Btrfs filesystem."
    exit 1
fi

# Check if the script is run in a chroot environment
if [ -n "$CHROOT" ] || [ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ]; then
    print_error "This script should not be run in a chroot environment."
    exit 1
fi

# Update the system and install base-devel and git
# check user input for skip this step or not
read -p "Execute step 1: update the system and install base-devel, git and usb network tethering library? (y/N) " update_choice
if [ "$update_choice" == "y" ]; then
    sudo pacman -Syu --noconfirm
    if [ $? -eq 0 ]; then
        print_success "System updated successfully."
    else
        print_error "Failed to update system."
        exit 1
    fi
    sudo pacman -S --noconfirm base-devel git libimobiledevice usbmuxd
    if [ $? -eq 0 ]; then
        print_success "base-devel and git installed successfully."
    else
        print_error "Failed to install base-devel and git."
        exit 1
    fi
fi

# Install yay for AUR package management
# check user input for skip this step or not
read -p "Execute step 2: install yay for AUR package management? (y/N) " yay_choice
if [ "$yay_choice" == "y" ]; then
    # Switch to a temporary directory in the user's home
    temp_dir="$ACTUAL_HOME/yay-build-temp"
    sudo -u "$ACTUAL_USER" mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    sudo -u "$ACTUAL_USER" git clone https://aur.archlinux.org/yay-bin.git
    if [ $? -ne 0 ]; then
        print_error "Failed to clone yay-bin repository."
        rm -rf "$temp_dir"
        exit 1
    fi
    cd yay-bin
    sudo -u "$ACTUAL_USER" makepkg -si --noconfirm
    if [ $? -eq 0 ]; then
        print_success "yay installed successfully."
    else
        print_error "Failed to install yay."
        cd ..
        rm -rf "$temp_dir"
        exit 1
    fi
    cd ..
    rm -rf "$temp_dir"
fi

# Install additional useful packages
# - neovim
# - zsh
# - gcc
# - cmake
# - python
# - python-pip
# - yazi
# - fzf
# - kitty
# - bat
# - eza
# - nautilus, nautilus-admin, nautilus-image-converter, nautilus-share
# - samba gvfs-smb
# - noto-fonts, noto-fonts-cjk, noto-fonts-emoji, ttf-jetbrains-mono
# - avahi, nss-mdns, gtk3, python-dbus, python-gobject

# check user input for skip this step or not
read -p "Execute step 3: install additional useful packages? (y/N) " install_choice
if [ "$install_choice" == "y" ]; then
    sudo pacman -S --noconfirm neovim zsh gcc cmake python python-pip yazi fzf kitty \
    bat eza nautilus nautilus-admin nautilus-image-converter nautilus-share samba gvfs-smb \
    noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-jetbrains-mono \
    avahi nss-mdns gtk3 python-dbus python-gobject

    if [ $? -eq 0 ]; then
        print_success "Additional packages installed successfully."
    else
        print_error "Failed to install some additional packages."
    fi
    
    # set up Avahi for mDNS support
    # After installation, you need to configure the `nsswitch.conf` file to include support for mDNS. 
    # Modify the `hosts` line in `/etc/nsswitch.conf` to include `mdns4_minimal` or `mdns_minimal` before `dns
    # This allows the system to resolve hostnames using mDNS.
    if grep -q "hosts:" /etc/nsswitch.conf; then
        sudo sed -i 's/hosts: .*/& mdns_minimal [NOTFOUND=return] dns/' /etc/nsswitch.conf
        if [ $? -eq 0 ]; then
            print_success "nsswitch.conf updated for mDNS support."
            sudo systemctl enable avahi-daemon
            sudo systemctl start avahi-daemon
        else
            print_error "Failed to update nsswitch.conf for mDNS support."
        fi
    else
        print_error "nsswitch.conf not found or does not contain 'hosts:' line."
    fi
fi

# Change Btrfs feature from `relatime` to `noatime`
# This is to improve performance and reduce disk writes
# by parsing /etc/fstab to find the Btrfs mount options
# look for any word that contains `relatime`
# and replace it with `noatime`
# check user input for skip this step or not
read -p "Execute step 3.1: change Btrfs feature from 'relatime' to 'noatime'? (y/N) " btrfs_choice
if [ "$btrfs_choice" == "y" ]; then
    fstab_file="/etc/fstab"
    if [ -f "$fstab_file" ]; then
        if grep -q "relatime" "$fstab_file"; then
            sudo sed -i 's/relatime/noatime/g' "$fstab_file"
            if [ $? -eq 0 ]; then
                print_success "Btrfs feature changed from 'relatime' to 'noatime' successfully."
            else
                print_error "Failed to change Btrfs feature in $fstab_file."
            fi
        else
            print_info "No 'relatime' found in $fstab_file, no changes made."
        fi
    else
        print_error "$fstab_file not found. Please ensure the file exists."
    fi
fi

# Optional feature: Backing up only .config directory from home directory
# This is useful for users who want to keep their configuration files
# check user input for skip this step or not
read -p "Execute step 3.2: backup .config directory? (y/N) " backup_choice
if [ "$backup_choice" == "y" ]; then
    # Create `/dotfiles` folders in root `sudo mkdir /dotfiles`, this is for store all config files from now on and will be snapshot along with `@` subvolume
    sudo mkdir -p /dotfiles
    if [ $? -eq 0 ]; then
        print_success "/dotfiles directory created successfully."
    else
        print_error "Failed to create /dotfiles directory."
        exit 1
    fi
    # Move the .config directory to /dotfiles
    if [ -d "$ACTUAL_HOME/.config" ]; then
        sudo mv "$ACTUAL_HOME/.config" /dotfiles/
        if [ $? -eq 0 ]; then
            print_success ".config directory backed up to /dotfiles successfully."
        else
            print_error "Failed to move .config directory to /dotfiles."
            exit 1
        fi
    else
        print_info "No .config directory found in $ACTUAL_HOME, nothing to back up."
    fi
    # Auto bind mount `/dotfiles` to `~/.config` by editing `/etc/fstab`
    if [ -f /etc/fstab ]; then
        echo "/dotfiles  $ACTUAL_HOME/.config  none  bind 0 0" | sudo tee -a /etc/fstab
        if [ $? -eq 0 ]; then
            print_success "/dotfiles successfully bind mounted to $ACTUAL_HOME/.config."
        else
            print_error "Failed to edit /etc/fstab."
        fi
    else
        print_error "/etc/fstab not found."
    fi
    # Change the ownership of `/dotfiles` to the actual user, `sudo chown -R {user}:{user} /dotfiles` (replace {user} with your actual username)
    sudo chown -R "$ACTUAL_USER":"$ACTUAL_USER" /dotfiles
    if [ $? -eq 0 ]; then
        print_success "Ownership of /dotfiles changed to $ACTUAL_USER."
    else
        print_error "Failed to change ownership of /dotfiles."
        exit 1
    fi
    # Test the bind mount
    sudo systemctl daemon-reload
    sudo mount "$ACTUAL_HOME/.config"
    if [ $? -eq 0 ]; then
        print_success "/dotfiles bind mount tested successfully."
    else
        print_error "Failed to test /dotfiles bind mount."
        exit 1
    fi

fi

# Set up timeshift for system snapshots
# check user input for skip this step or not
read -p "Execute step 4: set up timeshift for system snapshots? (y/N) " timeshift_choice
if [ "$timeshift_choice" == "y" ]; then
    sudo pacman -S --noconfirm timeshift lsb-release
    sudo timeshift --create --comments "Initial snapshot" --tags D
    # check the results of the snapshot creation
    if [ $? -eq 0 ]; then
        print_success "Timeshift snapshot created successfully."
    else
        print_error "Failed to create Timeshift snapshot."
    fi
fi

# After finding some bugs in the latest version of timeshift,
# we provide an option to downgrade to a more stable version
# check user input for skip this step or not
read -p "Execute step 4.1: Downgrade to the old version of timeshift? (y/N) " downgrade_choice
if [ "$downgrade_choice" == "y" ]; then
    # Check if yay is available
    if ! command -v yay &> /dev/null; then
        print_error "yay is not installed. Please install yay first (step 2)."
        exit 1
    fi

    sudo -u "$ACTUAL_USER" yay -S --noconfirm downgrade
    if [ $? -ne 0 ]; then
        print_error "Failed to install downgrade tool."
        exit 1
    fi
    
    # Check current version of timeshift
    current_version=$(timeshift --version 2>/dev/null | head -n1 | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
    print_info "Current timeshift version: $current_version"
    
    # Downgrade timeshift to version 24.01.1
    echo "y" | sudo downgrade --latest --prefer-cache --ignore always 'timeshift=24.01.1'

    # Check if the downgrade was successful
    if timeshift --version | grep -q "24.01.1"; then
        print_success "Downgrade to version 24.01.1 successful."
    else
        print_error "Downgrade to version 24.01.1 failed."
    fi
fi

# Install and set up grub-btrfs
# check user input for skip this step or not
read -p "Execute step 5: install and set up grub-btrfs? (y/N) " grub_choice
if [ "$grub_choice" == "y" ]; then
    sudo pacman -S --noconfirm grub-btrfs inotify-tools
    if [ $? -ne 0 ]; then
        print_error "Failed to install grub-btrfs or inotify-tools."
        exit 1
    fi
    
    sudo /etc/grub.d/41_snapshots-btrfs
    if [ $? -ne 0 ]; then
        print_error "Failed to run 41_snapshots-btrfs script."
        exit 1
    fi
    
    sudo grub-mkconfig -o /boot/grub/grub.cfg
    if [ $? -ne 0 ]; then
        print_error "Failed to generate grub configuration."
        exit 1
    fi
    
    # Check if grub-btrfs.cfg was created
    if [ -f /boot/grub/grub-btrfs.cfg ]; then
        print_success "grub-btrfs configuration created successfully."
    else
        print_error "grub-btrfs.cfg not found."
    fi
    
    # Enable and start grub-btrfsd daemon for automatic GRUB updates
    sudo systemctl daemon-reload
    sudo systemctl enable grub-btrfsd
    sudo systemctl start grub-btrfsd
    
    # Check the service health
    if systemctl is-active --quiet grub-btrfsd; then
        print_success "grub-btrfsd service is running."
    else
        print_warning "grub-btrfsd service is not running."
        print_info "Note: The service may still work correctly even if it shows as not running."
    fi
fi

# Install timeshift-autosnap
# check user input for skip this step or not
read -p "Execute step 6: install timeshift-autosnap? (y/N) " autosnap_choice
if [ "$autosnap_choice" == "y" ]; then
    # Check if yay is available
    if ! command -v yay &> /dev/null; then
        print_error "yay is not installed. Please install yay first (step 2)."
        exit 1
    fi
    
    sudo -u "$ACTUAL_USER" yay -S --noconfirm timeshift-autosnap
    if [ $? -ne 0 ]; then
        print_error "Failed to install timeshift-autosnap."
        exit 1
    fi

    # Change configuration if `grub-btrfs` has been installed on the system
    # This is to prevent timeshift-autosnap from updating GRUB configuration
    # check `grub-btrfs` installation
    if [ -f /boot/grub/grub-btrfs.cfg ]; then
        print_success "grub-btrfs detected, updating timeshift-autosnap configuration."
        # Create a backup of the configuration file
        sudo cp /etc/timeshift-autosnap.conf /etc/timeshift-autosnap.conf.bak
        if [ $? -eq 0 ]; then
            print_success "Backup of timeshift-autosnap configuration created."
        else
            print_error "Failed to create backup of timeshift-autosnap configuration."
            exit 1
        fi
        # looking for `updateGrub=true` and change to `updateGrub=false`
        sudo sed -i 's/updateGrub=true/updateGrub=false/' /etc/timeshift-autosnap.conf
        if [ $? -eq 0 ]; then
            print_success "Updated timeshift-autosnap configuration."
        else
            print_error "Failed to update timeshift-autosnap configuration."
            exit 1
        fi
    fi

    # Get snapshot count before installation
    snapshot_count_before=$(timeshift --list 2>/dev/null | grep -c "^[0-9]" || echo "0")
    
    print_info "Re-Installing git to test timeshift-autosnap functionality..."
    # check the results of the timeshift-autosnap installation
    # by install some package and check the snapshot
    sudo -u "$ACTUAL_USER" yay -S --noconfirm git
    
    # Wait a moment for snapshot creation
    sleep 5
    
    # Get snapshot count after installation
    snapshot_count_after=$(timeshift --list 2>/dev/null | grep -c "^[0-9]" || echo "0")
    
    # check the results of the snapshot creation
    timeshift --list
    
    # Verify if new snapshot was created
    if [ "$snapshot_count_after" -gt "$snapshot_count_before" ]; then
        print_success "New snapshot created successfully by timeshift-autosnap."
        print_info "Snapshots before: $snapshot_count_before, after: $snapshot_count_after"
    else
        print_warning "No new snapshot detected. timeshift-autosnap may not be working properly."
        print_info "Check timeshift-autosnap configuration."
    fi
fi

# Install and configure zsh with oh-my-zsh
# check user input for skip this step or not
read -p "Execute step 7: install and configure zsh with oh-my-zsh? (y/N) " zsh_choice
if [ "$zsh_choice" == "y" ]; then
    sudo pacman -S --noconfirm zsh
    if [ $? -ne 0 ]; then
        print_error "Failed to install zsh."
        exit 1
    fi
    
    # Check if yay is available for font installation
    if command -v yay &> /dev/null; then
        sudo -u "$ACTUAL_USER" yay -S --noconfirm ttf-meslo-nerd-font-powerlevel10k
        # sudo -u "$ACTUAL_USER" yay -S --noconfirm ttf-meslo-nerd
        if [ $? -eq 0 ]; then
            print_success "Meslo Nerd Font installed successfully."
        else
            print_warning "Failed to install Meslo Nerd Font, continuing without it."
        fi
    else
        print_warning "yay not available, skipping font installation."
    fi
    
    # Change default shell to zsh for target user
    chsh -s $(which zsh) "$ACTUAL_USER"
    if [ $? -eq 0 ]; then
        print_success "Default shell changed to zsh for $ACTUAL_USER."
    else
        print_error "Failed to change default shell to zsh for $ACTUAL_USER."
    fi
    
    # Install Oh My Zsh for the target user
    sudo -u "$ACTUAL_USER" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    # check the results of the oh-my-zsh installation
    if [ $? -eq 0 ]; then
        # Ensure proper ownership of zsh configuration
        chown -R "$ACTUAL_UID:$ACTUAL_GID" "$ACTUAL_HOME/.oh-my-zsh" 2>/dev/null || true
        chown "$ACTUAL_UID:$ACTUAL_GID" "$ACTUAL_HOME/.zshrc" 2>/dev/null || true
        print_success "Oh My Zsh installed successfully for $ACTUAL_USER."
    else
        print_error "Failed to install Oh My Zsh for $ACTUAL_USER."
    fi
fi

# Install and configure neovim with lazyvim
# check user input for skip this step or not
read -p "Execute step 8: install and configure neovim with lazyvim? (y/N) " nvim_choice
if [ "$nvim_choice" == "y" ]; then
    print_info "Installing LazyVim using the official starter template..."
    
    # Make comprehensive backup of current Neovim files (as per official docs)
    if [ -d "$ACTUAL_HOME/.config/nvim" ]; then
        print_info "Backing up existing neovim configuration for $ACTUAL_USER..."
        sudo -u "$ACTUAL_USER" mv "$ACTUAL_HOME/.config/nvim" "$ACTUAL_HOME/.config/nvim.bak"
    fi
    
    # Optional but recommended backups
    if [ -d "$ACTUAL_HOME/.local/share/nvim" ]; then
        print_info "Backing up neovim shared data..."
        sudo -u "$ACTUAL_USER" mv "$ACTUAL_HOME/.local/share/nvim" "$ACTUAL_HOME/.local/share/nvim.bak"
    fi
    
    if [ -d "$ACTUAL_HOME/.local/state/nvim" ]; then
        print_info "Backing up neovim state data..."
        sudo -u "$ACTUAL_USER" mv "$ACTUAL_HOME/.local/state/nvim" "$ACTUAL_HOME/.local/state/nvim.bak"
    fi
    
    if [ -d "$ACTUAL_HOME/.cache/nvim" ]; then
        print_info "Backing up neovim cache..."
        sudo -u "$ACTUAL_USER" mv "$ACTUAL_HOME/.cache/nvim" "$ACTUAL_HOME/.cache/nvim.bak"
    fi
    
    # Create .config directory if it doesn't exist
    sudo -u "$ACTUAL_USER" mkdir -p "$ACTUAL_HOME/.config"
    
    # Clone the LazyVim starter template (official method)
    sudo -u "$ACTUAL_USER" git clone https://github.com/LazyVim/starter "$ACTUAL_HOME/.config/nvim"
    
    if [ $? -eq 0 ]; then
        # Remove the .git folder so user can add it to their own repo later
        sudo -u "$ACTUAL_USER" rm -rf "$ACTUAL_HOME/.config/nvim/.git"
        
        # Ensure proper ownership
        chown -R "$ACTUAL_UID:$ACTUAL_GID" "$ACTUAL_HOME/.config/nvim"
        
        print_success "LazyVim starter installed successfully for $ACTUAL_USER."
        print_info "Please restart your terminal and run 'nvim' to complete the setup."
        print_info "Run ':LazyHealth' after installation to verify everything is working."
    else
        print_error "Failed to install LazyVim starter for $ACTUAL_USER."
    fi
fi

# Set the aliases for zsh
# check user input for skip this step or not
read -p "Execute step 9: set up zsh aliases? (y/N) " alias_choice
if [ "$alias_choice" == "y" ]; then
    ZSHRC_PATH="$ACTUAL_HOME/.zshrc"

    if [ -f "$ZSHRC_PATH" ]; then
        print_info "Setting up zsh aliases for user $ACTUAL_USER..."
        
        # Function to add alias if it doesn't already exist
        add_alias() {
            local alias_line="$1"
            if ! grep -Fxq "$alias_line" "$ZSHRC_PATH"; then
                echo "$alias_line" >> "$ZSHRC_PATH"
            fi
        }
        
        add_alias "alias ll='eza --icons -la'"
        add_alias "alias vim='nvim'"
        add_alias "alias cls='clear'"
        add_alias "alias update='sudo pacman -Syu'"
        add_alias "alias install='yay -S'"
        add_alias "alias remove='yay -Rns'"
        add_alias "alias search='yay -Ss'"
        add_alias "alias clean='yay -Rns \$(yay -Qdtq || true) && yay -Sc --noconfirm'"
        add_alias "alias ls='eza --icons'"
        add_alias "alias cat='bat'"
        add_alias "alias grep='grep --color=auto'"
        add_alias "alias fzf='fzf --preview \"bat --style=numbers --color=always --line-range :500 {}\"'"
        
        # Ensure proper ownership of .zshrc
        chown "$ACTUAL_UID:$ACTUAL_GID" "$ZSHRC_PATH"
        
        print_success "Zsh aliases set up successfully for $ACTUAL_USER."
    else
        print_error "$ZSHRC_PATH file not found. Please ensure zsh is installed and configured for $ACTUAL_USER."
    fi
fi

echo ""
echo "========================================="
echo "  Arch Linux Basic Setup Complete!"
echo "========================================="
echo ""
echo "Summary of what was configured for user: $ACTUAL_USER"
echo "- System packages and development tools"
echo "- yay AUR helper (if selected)"
echo "- Timeshift for system snapshots (if selected)"
echo "- GRUB-BTRFS for snapshot booting (if selected)"
echo "- Timeshift-autosnap for automatic snapshots (if selected)"
echo "- Zsh with Oh My Zsh (if selected)"
echo "- Neovim with LazyVim (if selected)"
echo "- Shell aliases for enhanced productivity (if selected)"
echo ""
echo "All user-specific configurations have been applied to: $ACTUAL_HOME"
echo ""
echo "Next steps:"
echo "1. Restart your terminal to use zsh (if installed)"
echo "2. Run 'nvim' to complete LazyVim setup (if installed)"
echo "3. Configure your shell and editor preferences"
echo ""
echo "Enjoy your Arch Linux setup!"

