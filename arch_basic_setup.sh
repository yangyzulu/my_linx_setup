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
    # Switch to a temporary directory in the user's home
    temp_dir="$ACTUAL_HOME/yay-build-temp"
    sudo -u "$ACTUAL_USER" mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    sudo -u "$ACTUAL_USER" git clone https://aur.archlinux.org/yay-bin.git
    if [ $? -ne 0 ]; then
        echo "[X] Failed to clone yay-bin repository."
        rm -rf "$temp_dir"
        exit 1
    fi
    cd yay-bin
    sudo -u "$ACTUAL_USER" makepkg -si --noconfirm
    if [ $? -eq 0 ]; then
        echo "[/] yay installed successfully."
    else
        echo "[X] Failed to install yay."
        cd ..
        rm -rf "$temp_dir"
        exit 1
    fi
    cd ..
    rm -rf "$temp_dir"
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
    
    sudo -u "$ACTUAL_USER" yay -S --noconfirm timeshift-autosnap
    if [ $? -ne 0 ]; then
        echo "[X] Failed to install timeshift-autosnap."
        exit 1
    fi
    
    # Get snapshot count before installation
    snapshot_count_before=$(timeshift --list 2>/dev/null | grep -c "^[0-9]" || echo "0")
    
    echo "Installing brave-bin to test timeshift-autosnap functionality..."
    # check the results of the timeshift-autosnap installation
    # by install some package and check the snapshot
    sudo -u "$ACTUAL_USER" yay -S --noconfirm brave-bin
    
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
        sudo -u "$ACTUAL_USER" yay -S --noconfirm ttf-meslo-nerd
        if [ $? -eq 0 ]; then
            echo "[/] Meslo Nerd Font installed successfully."
        else
            echo "[!] Failed to install Meslo Nerd Font, continuing without it."
        fi
    else
        echo "[!] yay not available, skipping font installation."
    fi
    
    # Change default shell to zsh for target user
    chsh -s $(which zsh) "$ACTUAL_USER"
    if [ $? -eq 0 ]; then
        echo "[/] Default shell changed to zsh for $ACTUAL_USER."
    else
        echo "[X] Failed to change default shell to zsh for $ACTUAL_USER."
    fi
    
    # Install Oh My Zsh for the target user
    sudo -u "$ACTUAL_USER" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    # check the results of the oh-my-zsh installation
    if [ $? -eq 0 ]; then
        # Ensure proper ownership of zsh configuration
        chown -R "$ACTUAL_UID:$ACTUAL_GID" "$ACTUAL_HOME/.oh-my-zsh" 2>/dev/null || true
        chown "$ACTUAL_UID:$ACTUAL_GID" "$ACTUAL_HOME/.zshrc" 2>/dev/null || true
        echo "[/] Oh My Zsh installed successfully for $ACTUAL_USER."
    else
        echo "[X] Failed to install Oh My Zsh for $ACTUAL_USER."
    fi
fi

# Install and configure neovim with lazyvim
# check user input for skip this step or not
read -p "Execute step 8: install and configure neovim with lazyvim? (y/n) " nvim_choice
if [ "$nvim_choice" == "y" ]; then
    echo "Installing LazyVim using the official starter template..."
    
    # Make comprehensive backup of current Neovim files (as per official docs)
    if [ -d "$ACTUAL_HOME/.config/nvim" ]; then
        echo "Backing up existing neovim configuration for $ACTUAL_USER..."
        sudo -u "$ACTUAL_USER" mv "$ACTUAL_HOME/.config/nvim" "$ACTUAL_HOME/.config/nvim.bak"
    fi
    
    # Optional but recommended backups
    if [ -d "$ACTUAL_HOME/.local/share/nvim" ]; then
        echo "Backing up neovim shared data..."
        sudo -u "$ACTUAL_USER" mv "$ACTUAL_HOME/.local/share/nvim" "$ACTUAL_HOME/.local/share/nvim.bak"
    fi
    
    if [ -d "$ACTUAL_HOME/.local/state/nvim" ]; then
        echo "Backing up neovim state data..."
        sudo -u "$ACTUAL_USER" mv "$ACTUAL_HOME/.local/state/nvim" "$ACTUAL_HOME/.local/state/nvim.bak"
    fi
    
    if [ -d "$ACTUAL_HOME/.cache/nvim" ]; then
        echo "Backing up neovim cache..."
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
        
        echo "[/] LazyVim starter installed successfully for $ACTUAL_USER."
        echo "    Please restart your terminal and run 'nvim' to complete the setup."
        echo "    Run ':LazyHealth' after installation to verify everything is working."
    else
        echo "[X] Failed to install LazyVim starter for $ACTUAL_USER."
    fi
fi

# Set the aliases for zsh
# check user input for skip this step or not
read -p "Execute step 9: set up zsh aliases? (y/n) " alias_choice
if [ "$alias_choice" == "y" ]; then
    ZSHRC_PATH="$ACTUAL_HOME/.zshrc"

    if [ -f "$ZSHRC_PATH" ]; then
        echo "Setting up zsh aliases for user $ACTUAL_USER..."
        
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
        
        echo "[/] Zsh aliases set up successfully for $ACTUAL_USER."
    else
        echo "[X] $ZSHRC_PATH file not found. Please ensure zsh is installed and configured for $ACTUAL_USER."
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

