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

# Install basic packages for Arch Linux setup

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Please use sudo."
    exit 1
fi

# Check if the script is run on Arch Linux
if [ ! -f /etc/arch-release ]; then
    echo "This script is intended for Arch Linux only."
    exit 1
fi

# Check if the script is run on a Btrfs filesystem
if ! mount | grep -q "type btrfs"; then
    echo "This script is intended for systems with Btrfs filesystem."
    exit 1
fi

# Check if the script is run in a chroot environment
if [ -n "$CHROOT" ]; then
    echo "This script should not be run in a chroot environment."
    exit 1
fi

# Update the system and install base-devel and git
# check user input for skip this step or not
read -p "Execute step 1: update the system and install base-devel and git? (y/n) " update_choice
if [ "$update_choice" == "y" ]; then
    sudo pacman -Syu --noconfirm
    if [ $? -eq 0 ]; then
        echo "[/] System updated successfully."
    else
        echo "[X] Failed to update system."
        exit 1
    fi
    sudo pacman -S --noconfirm base-devel git
    if [ $? -eq 0 ]; then
        echo "[/] base-devel and git installed successfully."
    else
        echo "[X] Failed to install base-devel and git."
        exit 1
    fi
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
# check user input for skip this step or not
read -p "Execute step 2: install additional useful packages? (y/n) " install_choice
if [ "$install_choice" == "y" ]; then
    sudo pacman -S --noconfirm neovim zsh gcc cmake python python-pip yazi fzf kitty bat eza
    if [ $? -eq 0 ]; then
        echo "[/] Additional packages installed successfully."
    else
        echo "[X] Failed to install some additional packages."
    fi
fi

# Install yay for AUR package management
# check user input for skip this step or not
read -p "Execute step 3: install yay for AUR package management? (y/n) " yay_choice
if [ "$yay_choice" == "y" ]; then
    git clone https://aur.archlinux.org/yay-bin.git
    if [ $? -ne 0 ]; then
        echo "[X] Failed to clone yay-bin repository."
        exit 1
    fi
    cd yay-bin
    makepkg -si --noconfirm
    if [ $? -eq 0 ]; then
        echo "[/] yay installed successfully."
    else
        echo "[X] Failed to install yay."
        cd ..
        rm -rf yay-bin
        exit 1
    fi
    cd ..
    rm -rf yay-bin
fi

# Set up timeshift for system snapshots
# check user input for skip this step or not
read -p "Execute step 4: set up timeshift for system snapshots? (y/n) " timeshift_choice
if [ "$timeshift_choice" == "y" ]; then
    sudo pacman -S --noconfirm timeshift
    sudo timeshift --create --comments "Initial snapshot" --tags D
    # check the results of the snapshot creation
    if [ $? -eq 0 ]; then
        echo "[/] Timeshift snapshot created successfully."
    else
        echo "[X] Failed to create Timeshift snapshot."
    fi
fi

# Install and set up grub-btrfs
# check user input for skip this step or not
# - Install `sudo pacman -S grub-btrfs`
#   - Test the script `sudo /etc/grub.d/41_snapshots-btrfs`
#   - Run this once `sudo grub-mkconfig -o /boot/grub/grub.cfg`
#   - Check the entry `ls /boot/grub/grub-btrfs.cfg`
# - Install `sudo pacman -S inotify-tools`
# - Change config file from Snapper to Timeshift
#   - Replace the grub-btrfs config file with the one from this repository
#   - `sudo cp ./grub-btrfs.service /usr/lib/systemd/system/grub-btrfsd.service`
# - Auto start the daemon `sudo systemctl enable grub-btrfsd` and start it `sudo systemctl start grub-btrfsd`
# - Check the service health `journalctl -f`, if no error = OK
read -p "Execute step 5: install and set up grub-btrfs? (y/n) " grub_choice
if [ "$grub_choice" == "y" ]; then
    sudo pacman -S --noconfirm grub-btrfs inotify-tools
    if [ $? -ne 0 ]; then
        echo "[X] Failed to install grub-btrfs or inotify-tools."
        exit 1
    fi
    
    sudo /etc/grub.d/41_snapshots-btrfs
    if [ $? -ne 0 ]; then
        echo "[X] Failed to run 41_snapshots-btrfs script."
        exit 1
    fi
    
    sudo grub-mkconfig -o /boot/grub/grub.cfg
    if [ $? -ne 0 ]; then
        echo "[X] Failed to generate grub configuration."
        exit 1
    fi
    
    # Check if grub-btrfs.cfg was created
    if [ -f /boot/grub/grub-btrfs.cfg ]; then
        echo "[/] grub-btrfs configuration created successfully."
    else
        echo "[X] grub-btrfs.cfg not found."
    fi
    if [ ! -f "./grub-btrfs.service" ]; then
        echo "[X] grub-btrfs.service file not found in current directory."
        echo "    Please ensure the file exists before running this script."
    else
        sudo cp ./grub-btrfs.service /usr/lib/systemd/system/grub-btrfsd.service
        if [ $? -eq 0 ]; then
            echo "[/] grub-btrfs.service copied successfully."
        else
            echo "[X] Failed to copy grub-btrfs.service."
        fi
    fi
    sudo systemctl enable grub-btrfsd
    sudo systemctl start grub-btrfsd
    # Check the service health
    if systemctl is-active --quiet grub-btrfsd; then
        echo "[/] grub-btrfsd service is running."
    else
        echo "[X] grub-btrfsd service is not running."
    fi
fi

# Install timeshift-autosnap
# check user input for skip this step or not
read -p "Execute step 6: install timeshift-autosnap? (y/n) " autosnap_choice
if [ "$autosnap_choice" == "y" ]; then
    # Check if yay is available
    if ! command -v yay &> /dev/null; then
        echo "[X] yay is not installed. Please install yay first (step 3)."
        exit 1
    fi
    
    yay -S --noconfirm timeshift-autosnap
    if [ $? -ne 0 ]; then
        echo "[X] Failed to install timeshift-autosnap."
        exit 1
    fi
    
    # Get snapshot count before installation
    snapshot_count_before=$(timeshift --list 2>/dev/null | grep -c "^[0-9]" || echo "0")
    
    echo "Installing brave-bin to test timeshift-autosnap functionality..."
    # check the results of the timeshift-autosnap installation
    # by install some package and check the snapshot
    yay -S --noconfirm brave-bin
    
    # Wait a moment for snapshot creation
    sleep 5
    
    # Get snapshot count after installation
    snapshot_count_after=$(timeshift --list 2>/dev/null | grep -c "^[0-9]" || echo "0")
    
    # check the results of the snapshot creation
    timeshift --list
    
    # Verify if new snapshot was created
    if [ "$snapshot_count_after" -gt "$snapshot_count_before" ]; then
        echo "[/] New snapshot created successfully by timeshift-autosnap."
        echo "    Snapshots before: $snapshot_count_before, after: $snapshot_count_after"
    else
        echo "[X] No new snapshot detected. timeshift-autosnap may not be working properly."
        echo "    Check timeshift-autosnap configuration."
    fi
fi

# Install and configure zsh with oh-my-zsh
# check user input for skip this step or not
read -p "Execute step 7: install and configure zsh with oh-my-zsh? (y/n) " zsh_choice
if [ "$zsh_choice" == "y" ]; then
    sudo pacman -S --noconfirm zsh
    if [ $? -ne 0 ]; then
        echo "[X] Failed to install zsh."
        exit 1
    fi
    
    # Check if yay is available for font installation
    if command -v yay &> /dev/null; then
        yay -S --noconfirm ttf-meslo-nerd
        if [ $? -eq 0 ]; then
            echo "[/] Meslo Nerd Font installed successfully."
        else
            echo "[!] Failed to install Meslo Nerd Font, continuing without it."
        fi
    else
        echo "[!] yay not available, skipping font installation."
    fi
    
    # Change default shell to zsh for current user
    chsh -s $(which zsh)
    if [ $? -eq 0 ]; then
        echo "[/] Default shell changed to zsh."
    else
        echo "[X] Failed to change default shell to zsh."
    fi
    
    # Install Oh My Zsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    # check the results of the oh-my-zsh installation
    if [ $? -eq 0 ]; then
        echo "[/] Oh My Zsh installed successfully."
    else
        echo "[X] Failed to install Oh My Zsh."
    fi
fi

# Install and configure neovim with lazyvim
# check user input for skip this step or not
read -p "Execute step 8: install and configure neovim with lazyvim? (y/n) " nvim_choice
if [ "$nvim_choice" == "y" ]; then
    # Backup existing neovim config if it exists
    if [ -d ~/.config/nvim ]; then
        echo "Backing up existing neovim configuration..."
        mv ~/.config/nvim ~/.config/nvim.backup.$(date +%Y%m%d_%H%M%S)
    fi
    
    git clone https://github.com/LazyVim/LazyVim.git ~/.config/nvim
    # check the results of the LazyVim installation
    if [ $? -eq 0 ]; then
        echo "[/] LazyVim installed successfully."
        echo "    Please restart your terminal and run 'nvim' to complete the setup."
    else
        echo "[X] Failed to install LazyVim."
    fi
fi

echo ""
echo "========================================="
echo "  Arch Linux Basic Setup Complete!"
echo "========================================="
echo ""
echo "Summary of what was configured:"
echo "- System packages and development tools"
echo "- yay AUR helper (if selected)"
echo "- Timeshift for system snapshots (if selected)"
echo "- GRUB-BTRFS for snapshot booting (if selected)"
echo "- Timeshift-autosnap for automatic snapshots (if selected)"
echo "- Zsh with Oh My Zsh (if selected)"
echo "- Neovim with LazyVim (if selected)"
echo ""
echo "Next steps:"
echo "1. Restart your terminal to use zsh (if installed)"
echo "2. Run 'nvim' to complete LazyVim setup (if installed)"
echo "3. Configure your shell and editor preferences"
echo ""
echo "Enjoy your Arch Linux setup!"

