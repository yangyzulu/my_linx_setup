# My Linux environment preferences

## For All Ubuntu

- [x] Check that you install the OS with btrfs

- [x] `sudo apt update ; sudo apt upgrade -y`

- [x] Check the boot up speed using
  
  ```bash
  systemd-analyze
  systemd-analyze blame
  systemd-analyze critical-chain
  ```

- [x] Disable NetworkManager-wait-online.service

- [x] Install Timeshift and make the first backup

- [x] Setup grub-btrfs (for access snapshot directly via grub)  
  
  - !! **<mark>Don't use</mark>** *grub-customizer* as it will proxy the grub configuration and **<u>prevent</u>** the snapshot submenu entries to load correctly !!

- [x] Install [**Timeshift-autosnap**](https://github.com/wmutschl/timeshift-autosnap-apt)

- [x] Test and confirm that snapshot entries accessible
  
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

- [x] Install the lastest MESA driver (VGA driver, recommended for AMD GPU) (detected <u>some bug</u> with 25.04)
  
  ```bash
  sudo add-apt-repository ppa:oibaf/graphics-drivers
  sudo apt update
  sudo apt upgrade
  ```

- [x] Correct the behavior of the fingerprint authentication when the lid closed. (fix pam.d) (noted in `./Laptop_lid_state_authentication.md`)

- [x] Install preload (analyzes user behavior and frequently run applications)

- [x] Install Brave browser and config it to use wayland (brave://flags, search for 'ozone')
  
  - Bitwarden extension
  - Line extension
  - Amplenote capture extension

- [x] Install [Thinkfan](https://github.com/vmatare/thinkfan) and set fan level base on temp. Use thinkfan.conf in this folder. (*<u>No need for 25.04</u>*, default power manager can set the fan to 0 RPM and 24.04 can't)

- [x] Install Flatpak & Flathub
  
  - (Optional) On some fresh OS installation you should run `flatpak install flathub xxx` to install some simple thing first. This may download/fix some of the flatpak confliction with the OS and make flatpak perform properly and faster

- [x] Install Font manager and install Thai Sarabun from google font (inside the Font manager option)

- [x] Install [MarkText](https://github.com/marktext/marktext/releases) via link or flatpak

- [x] Install zsh `sudo apt install zsh`
  
  Make it your default shell: `chsh -s $(which zsh)`

- [x] Install oh-my-zsh 
  
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

- [x] alias alternative app (ls = eza, nano = micro)
  
  ```bash
  # exist code . . .
  # add below
  alias ls="eza -l --icons -s extension"
  # alias add_ssh="ssh-add ~/.ssh/eos_gitea"
  ```

- [x] Install ttf-mscorefonts-installer
  
  `sudo apt install ttf-mscorefonts-installer`

- [x] Install [draggy](https://github.com/daveriedstra/draggy?tab=readme-ov-file#dependencies) (3-finger drag gesture)

- [x] Install [logiops](https://github.com/PixlOne/logiops/releases) (unlock Logitech MX master mouse potential, use the conf file inside the folder)

- [x] Install Mission Center via flatpak

- [x] Install [Rustdesk](https://github.com/rustdesk/rustdesk/releases/tag/1.4.0)

- [x] Install [Netbird](https://nb.eosgate.org)

- [ ] Install Vivado (don't forget to install `libtinfo5 libncurse5` ...)

- [x] Install GNU Radio
  
  - gr-satellite
  - gr-eostools
  - uhd-host, libuhd-dev

- [x] Install VS code

- [x] Install Onlyoffice via flatpak

- [x] Install Nextcloud `sudo apt install nextcloud-desktop`
  
  - connect to server
  - mount drive with WebDAV

- [x] Install [AppImageLauncher](https://github.com/TheAssassin/AppImageLauncher) (Recommended only install on early 24.04)

## In testing

- [ ] Enable auto-unlock Kwallet/gnome-keyring by remove '-' inside /pam.d/sddm(KDE) or /pam.d/xxx(Gnome)
- [x] Install [WineHQ](https://gitlab.winehq.org/wine/wine/-/wikis/Debian-Ubuntu) (use `devel` branch for `Line` compatibility) (**<u>Unstable, but usable</u>**)

---

## For Gnome desktop

- [x] Setup keyboard shortcut
  
  - Meta + B = browser
  - Meta + Enter = terminal
  - Meta + E = file home
  - Meta + W = setting
  - Meta + ESC = monitor 
  - Meta + Tab/S.Tab = Switch workspace
  - Meta + Ctrl + Tab/S.Tab = Move window to workspace

- [x] Setup Gnome tweak, go through all tab and configure them.

- [x] Setup Gnome extension.
  
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
    
    - Add a special udev rules to `60-ddcutil-i2c.rules`, if the <mark>screen freeze</mark> problem occured. Disable the extension first by connect the laptop to a external display
      
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

- [x] Enable 'New Documents' context menu option (save .txt file in 'Templates' floder)

- [x] **`Fix`** the wifi switching bug (detected on Ubuntu 25.04)
  
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

- [x] **`Fix`** Error pop up about control center (Detected on Ubuntu 25.04)
  
  - Looking for the binary that use for execute that error (usually *gnome-control-center-...)
  - move that file to another directory

- [x] **`Fix`** Update information with (null) detail (Detected on Ubuntu 25.04)
  
  - Disable `update-notifier.service` 
  
  - This will <u>***disable***</u> all auto update

---

## For KDE desktop

- [ ] Set up keybinding
  
  - Switch focus window
  
  - Switch desktop
  
  - Move window to desktop
  
  - Move window inside desktop
  
  - Meta + B = browser
  
  - Meta + Enter = terminal
    
    - Meta + ESC = mission center
