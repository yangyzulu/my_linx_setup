# My Hyprland environment preferences

## ArchInstall

- Download and make a bootable USB drive

- Boot to the drive

- Connect to the internet
  
  - Wi-fi `iwctl`
    
    ```bash
    # inside `iwctl`
    station wlan0 scan
    station wlan0 connect {AP name}
    # input the AP password
    exit
    ```
  
  - Test the connection `ping 1.1.1.1`

- Start the installation `archinstall`
  
  - Complete each step carefully
  
  - Select `...Network manager...` on the network section
  
  - Install extra pacakage 
    
    ```shell
    - git
    - wget
    - curl
    - neovim
    - zsh
    - base-devel
    - gcc
    - cmake
    ```
  
  - **Tips :** type `/` for search anything in the list menu, very useful for list selection

- Installation will **<u>not</u>** included any desktop environtment

- Reboot the system

## Basic desktop environtment install

- Update the system `sudo pacman -Syu`

- Install login manager and terminal `sudo pacman -S gdm kitty`

- Install Samba support for Nautilus `sudo pacman -S samba gvfs-smb`

- Reboot the system, you should find the working login screen. Now the basic environment is ready for the next installation

## Snapshot system

- Check that you install the OS with btrfs `sudo btrfs subvolume list /`

- Check the boot up speed using
  
  ```bash
  systemd-analyze
  systemd-analyze blame
  systemd-analyze critical-chain
  ```

- Disable NetworkManager-wait-online.service

- Install `Timeshift` , `sudo pacman -S timeshift`
  
  - Make the first backup `sudo timeshift --create --comments "First snap" --tags D`

- Setup `grub-btrfs` (for access snapshot directly via grub)  
  
  - !! **<u>Don't use</u>** *grub-customizer* as it will proxy the grub configuration and **<u>prevent</u>** the snapshot submenu entries to load correctly !!
  - Install `sudo pacman -S grub-btrfs`
    - Test the script `sudo /etc/grub.d/41_snapshots-btrfs`
    - Run this once `sudo grub-mkconfig -o /boot/grub/grub.cfg`
    - Check the entry `ls /boot/grub/grub-btrfs.cfg`
  - Install `sudo pacman -S inotify-tools`
  - Change config file from Snapper to Timeshift
    - `sudo systemctl edit --full grub-btrfsd`
    - Looking for `./snapper` , change to `-t` and save the file
  - Auto start the daemon `sudo systemctl enable grub-btrfsd` and start it `sudo systemctl enable grub-btrfsd`
  - Check the service health `journalctl -f`, if no error = OK

- Install [YAY: Yet another Yogurt - An AUR Helper written in Go](https://github.com/Jguer/yay)
  
  ```bash
  sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si
  ```
  
  - Use `yay -Y --gendb` to generate a development package database for `*-git` packages that were installed without yay. This command should only be run once.
  
  - `yay -Syu --devel` will then check for development package updates
  
  - Use `yay -Y --devel --save` to make development package updates permanently enabled (`yay` and `yay -Syu` will then always check dev packages)

- Install [**Timeshift-autosnap**](https://github.com/wmutschl/timeshift-autosnap-apt) 
  
  - `yay -S timeshift-autosnap`
  
  - Change configuration if needed, `sudo nano /etc/timeshift-autosnap.conf`
  
  - Can test with install something `sudo pacman -S brave-bin`, the snapshot should created automatically

- Test and confirm that snapshot entries accessible
  
  ```bash
  sudo nano /etc/default/grub
  ```
  
  - temporary change the `GRUB_TIMEOUT_STYLE`
  
  ```bash
  GRUB_TIMEOUT_STYLE=menu
  # GRUB_TIMEOUT_STYLE=hidden
  GRUB_TIMEOUT=5
  ```
  
  - After snapshot submenu verification, change the setting back to normal

## Necessary applications

- Install the lastest MESA driver (VGA driver, recommended for AMD GPU) (detected <u>some bug</u> with 25.04)
  
  ```bash
  sudo add-apt-repository ppa:oibaf/graphics-drivers
  sudo apt update
  sudo apt upgrade
  ```

- Correct the behavior of the fingerprint authentication when the lid closed. (fix pam.d) (noted in `./Laptop_lid_state_authentication.md`)

- Install preload (analyzes user behavior and frequently run applications)

- Install Brave browser and config it to use wayland (brave://flags, search for 'ozone')
  
  - Bitwarden extension
  - Line extension

- Install [Thinkfan](https://github.com/vmatare/thinkfan) and set fan level base on temp. Use thinkfan.conf in this folder. (*<u>No need for 25.04</u>*, default power manager can set the fan to 0 RPM but 24.04 can't)

- Install Flatpak & Flathub
  
  - (Optional) On some fresh OS installation you should run `flatpak install flathub xxx` to install some simple thing first. This may download/fix some of the flatpak confliction with the OS and make flatpak perform properly and faster

- Install Font manager and install Thai Sarabun from google font (inside the Font manager option)

- Install [MarkText](https://github.com/marktext/marktext/releases) via `yay -S marktext` or flatpak

- Install zsh `sudo pacman -S zsh`
  
  Make it your default shell: `chsh -s $(which zsh)`

- Install oh-my-zsh 
  
  ```bash
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  ```
  
  Font: [MesloLGF NF](https://github.com/romkatv/powerlevel10k?tab=readme-ov-file#manual-font-installation)
  
  Theme: power10k
  
  ```bash
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
  ```
  
  Plugin: autosuggestion+fastsyntaxhighlight
  
  ```bash
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
  git clone https://github.com/z-shell/F-Sy-H.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/F-Sy-H
  ```
  
  Open `~/.zshrc`, find the line that sets `ZSH_THEME`, and change its value to `"powerlevel10k/powerlevel10k"`

- alias alternative app (ls = eza, nano = micro)
  
  ```bash
  # exist code . . .
  # add below
  alias ls="eza -l --icons -s type"
  # alias add_ssh="ssh-add ~/.ssh/eos_gitea"
  ```

- Install ttf-mscorefonts-installer
  
  `sudo apt install ttf-mscorefonts-installer`

- Install [draggy](https://github.com/daveriedstra/draggy?tab=readme-ov-file#dependencies) (3-finger drag gesture)

- Install [logiops](https://github.com/PixlOne/logiops/releases) (unlock Logitech MX master mouse potential, use the conf file inside the folder)

- Install Mission Center via flatpak, Or `btop`

- Install [Rustdesk](https://github.com/rustdesk/rustdesk/releases/tag/1.4.0)

- Install [Netbird](https://nb.eosgate.org)

- Install Vivado (don't forget to install `libtinfo5 libncurse5` ...)

- Install GNU Radio
  
  - gr-satellite
  - gr-eostools
  - uhd-host, libuhd-dev

- Install VS code

- Install Onlyoffice via flatpak

- Install Nextcloud `sudo apt install nextcloud-desktop`
  
  - connect to server
  - mount drive with WebDAV

- Install [AppImageLauncher](https://github.com/TheAssassin/AppImageLauncher) (Recommended only install on early 24.04)

## Hyprland ricing session

- Install hyprland `sudo pacman -S hyprland kitty ttf-meslo-nerd brave-bin`

- Install hyprland accessories `sudo pacman -S hyprlock hyprpaper hypridle kanshi`

- <mark>TODO</mark> Test `waybar` or use `hyprpanel`

- <mark>TODO</mark> Test `wofi` or `rofi`

- Clone the dotfile from Github 
  
  `git clone https://github.com/yangyzulu/my_linx_setup.git` 
  
  or copy from samba NAS, mount drive using `nautilus`
  
  `smb://nkrafapegasus.synology.me/satellite/dotfiles`

- Run `install.sh`, the script will put all the files inside the folder to where they belong <mark>TODO</mark> make the `install.sh` script *(don't foget Kanshi systemd setup)*

- **<mark>URGENT</mark>** This rice is fricken awsome, [GitHub - caelestia-dots/caelestia: A very segsy rice](https://github.com/caelestia-dots/caelestia)
  
  - Start with install entire shell then tweaking it later
  
  - Go with manual installation (`yay` should be installed)
    
    ```bash
      yay -S hyprland hyprpicker hypridle xdg-desktop-portal-hyprland xdg-desktop-portal-gtk wl-clipboard cliphist bluez-utils inotify-tools wireplumber trash-cli foot fastfetch btop jq socat imagemagick curl adw-gtk-theme papirus-icon-theme qt5ct qt6ct ttf-jetbrains-mono-nerd zsh app2unit
      # not necessary for me
      fish starship
    ```

- <mark>TODO</mark> Adapt Omarchy config to my config (touchpad gesture, animation, keybinding)

- <mark>TODO </mark> Try setup screencapture button on waybar using `hyprshot` or looking for 

- <mark>TODO</mark> Make Monitor mode button work with Kanshi.
  
  - Make `waybar` or `hyprpanel` custom module. Execute `kanshi {profile name}` when press the button or click on the panel.

- <mark>TODO</mark> Install `LazyVim`

- <mark>TODO</mark> Setup `Window rules` for pop up dialog 

- Install GTK-Theme for GTK app
  
  - Install GTK theme selector `sudo pacman -S nwg-look`
  
  - Clone the [Graphite gtk theme](https://github.com/vinceliuice/Graphite-gtk-theme?tab=readme-ov-file) 
    
    ```bash
    git clone https://github.com/vinceliuice/Graphite-gtk-theme.git
    ```
  
  - Install the theme
    
    ```bash
    sudo ./install.sh -c dark -s standard -s compact -l -g --tweaks black rimless
    ```
  
  - Run `nwg-look` , select the theme, adjust font rendering `font aa: rgba`

- Install `suda.vim` plugin into LazyVim 
  
  - Create a new file under the lua/plugins directory (if it doesn't exist, create it). For example:  `nvim ~/.config/nvim/lua/plugins/suda.lua`
  
  - Add the following Lua code to register `suda.vim` as a plugin:
    
    ```lua
    return {
      "lambdalisue/suda.vim",
    }
    ```
  
  - Save the file and restart Neovim. The LazyVim will automatically clone the plugin and install it
  
  - Usage:
    
    ```vim
    # Read with sudo
    :SudaRead
    # Write with sudo
    :SudaWrite
    ```

- Install `CarbonFox` theme to LazyVim (Dark theme)
  
  - Create a new file under the lua/plugins directory (if it doesn't exist, create it). For example: `nvim ~/.config/nvim/lua/plugins/colorscheme.lua`
  
  - Add the following Lua code to register as a new plugin, put the blacket inside return:
    
    - ```lua
      return {
          { "EdenEast/nightfox.nvim" } -- lazy
      }
      ```
  
  - Go to Lazy home and let it clone the plugin first or just restart neovim
  
  - Apply the color scheme `:colorscheme carbonfox`

## In testing

- Install [WineHQ](https://gitlab.winehq.org/wine/wine/-/wikis/Debian-Ubuntu) (use `devel` branch for `Line` compatibility) (**<u>Looks buggy, but usable</u>**)

---

## For Gnome desktop ricing

- Setup keyboard shortcut
  
  - Meta + B = browser
  - Meta + Enter = terminal
  - Meta + E = file home
  - Meta + W = setting
  - Meta + ESC = monitor 
  - Meta + Tab/S.Tab = Switch workspace
  - Meta + Ctrl + Tab/S.Tab = Move window to workspace

- Setup Gnome tweak, go through all tab and configure them.

- Setup Gnome extension.
  
  - ***Choose between 1 or 2***
    
    1. ***Tiling shell***
       
       - Set Inner&Outer gaps to 1
       
       - Disable `Tiling System deact key` and `Span multiple tiles`
       
       - Set the keybinding
    
    2. ***Gnome tiling windows***
       
       - Set tiling behavior
         - Disable `Tiling Popup`
         - Set `Dynamic Keybinding Behavior` to _Tiling State_
       - Disable all default Keybindings
         - Set `Edge Tiling` Meta + ⬆️⬇️⬅️➡️
  
  - ***Touchpad Gesture*** to disable all 3-finger gestures on touchpad.
  
  - ***Vitals*** monitor CPU temp and fan RPM
  
  - ***Just Perfection*** detail desktop adjustment
  
  - ***Emoji copy*** for emoji typing and hide the icon on top panel
  
  - ***Primary Input on LockScreen***
  
  - Setup [***Display Brightness Control using ddcutil***](https://github.com/daitj/gnome-display-brightness-ddcutil#setup-ddcutil)
    
    - Install ddcutil first `sudo apt install ddcutil`
    
    - Create i2c group and add yourself
      
      ```bash
      sudo groupadd --system i2c
      sudo usermod $USER -aG i2c
      ```
    
    - Add a special udev rules to `60-ddcutil-i2c.rules`, if the <u>screen freeze</u> problem occured. Disable the extension first by connect the laptop to a external display
      
      ```bash
      # find the problematic screen (usually the laptop internal screen)
      ddcutil --breif detect
      # looking for the i2c device of the problematic screen (eg./dev/i2c-7)
      # add below to the bottom of /usr/lib/udev/60-ddcutil-i2c.rules file
      KERNEL=="i2c-7", OWNER="root", GROUP="root", MODE="0600"
      ```
    
    - Log out the session or restart the system
    
    - Check that the rules applied, `ddcutil --breif detect` should not output the problematic display anymore
    
    - Enable the extension again

- Enable 'New Documents' context menu option (save .txt file in 'Templates' floder)

- **`Fix`** the wifi switching bug (detected on Ubuntu 25.04)
  
  - ~~Install the amdgpu_install package~~ (Get just little difference from Mesa driver, not worth install)
    
    > ~~cd Downloads
    > wget https://repo.radeon.com/amdgpu-install/6.4.1/ubuntu/noble/amdgpu-install_6.4.60401-1_all.deb
    > sudo apt install mesa-amdgpu-common-dev mesa-amdgpu-va-drivers mesa-amdgpu-vdpau-drivers mesa-amdgpu-libgallium~~
  
  - Edit the line below in `/etc/default/grub` then reboot
    
    ```bash
    # ... existing code ...
    GRUB_CMDLINE_LINUX_DEFAULT="quiet amdgpu.dcdebugmask=0x600"
    # ... existing code ...
    ```

- **`Fix`** Error pop up about control center (Detected on Ubuntu 25.04)
  
  - Looking for the binary that use for execute that error (usually *gnome-control-center-...)
  - move that file to another directory

- **`Fix`** Update information with (null) detail (Detected on Ubuntu 25.04)
  
  - Disable `update-notifier.service` 
  
  - This will <u>***disable***</u> all auto update
