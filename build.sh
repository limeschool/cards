#!/bin/bash
export HOME=~
export PROFILE=${HOME}/cards-profile
export LOCAL_REPO=${HOME}/local-repo
set +h
umask 0022 # Correct file permissions
cd ${HOME}

pacman -Syu archiso git base-devel --noconfirm # Install packages we'll need to build

# Install aurutils to build our local repository from AUR packages
git clone https://aur.archlinux.org/aurutils.git
cd aurutils
makepkg -si

# Begin setting up our profile
cp -r /usr/share/archiso/configs/releng/ ${PROFILE}
cp -rf ./cards/. ${PROFILE}
mkdir ${LOCAL_REPO}

# Add repositories to our profile
tee -a ${PROFILE}/pacman.conf > /dev/null <<EOT
[cards]
SigLevel = Optional TrustAll
Server = file://${LOCAL_REPO}

[extra-alucryd]
Server = https://pkgbuild.com/~alucryd/$repo/$arch
EOT

# Add packages to our local repository (shared between host and profile)
# 1. Add repositories to our host
tee -a /etc/pacman.conf > /dev/null <<EOT
[cards]
SigLevel = Optional TrustAll
Server = file://${LOCAL_REPO}

[extra-alucryd]
Server = https://pkgbuild.com/~alucryd/$repo/$arch
EOT

# 2. Add our packages from the AUR
aur sync -C ttf-raleway
aur sync -C gnome-settings-daemon-elementary
aur sync -C elementary-wallpapers-git
aur sync -C pantheon-default-settings
aur sync -C pantheon-session-git
aur sync -C switchboard-plug-elementary-tweaks-git
aur sync -C pantheon-screencast
aur sync -C pantheon-system-monitor-git
aur sync -C pantheon-mail-git
aur sync -C elementary-planner-git

# Add packages from Arch's repositories to our profile
tee -a ${PROFILE}/packages.x86_64 > /dev/null <<EOT
## X11 and drivers
xorg
xorg-server
xorg-drivers
xorg-xinit
xorg-xclock
xorg-twm
xterm
xf86-input-libinput
mesa
noto-fonts
ttf-hack
libva
libva-mesa-driver
intel-ucode
intel-tbb

## Wayland
wayland
wayland-protocols
glfw-wayland
qt5-wayland
xorg-server-xwayland
wlc

## Display & Misc. Desktop Environment
lightdm
nvidia-dkms
vulkan-radeon
qt5-svg
qt5-translations
gnome-disk-utility

## Pantheon
capnet-assist
contractor
cups
cups-pk-helper
elementary-icon-theme
elementary-wallpapers
epiphany
file-roller
gala
gnu-free-fonts
gtk-engine-murrine
gtk-theme-elementary
gtkspell3
gvfs
gvfs-afc
gvfs-mtp
gvfs-nfs
gvfs-smb
light-locker
lightdm-pantheon-greeter
pantheon
pantheon-applications-menu
pantheon-calculator
pantheon-calendar
pantheon-camera
pantheon-code
pantheon-dpms-helper
pantheon-files
pantheon-geoclue2-agent
pantheon-music
pantheon-photos
pantheon-polkit-agent
pantheon-print
pantheon-screenshot
pantheon-shortcut-overlay
pantheon-terminal
pantheon-videos
plank
pulseaudio-bluetooth
simple-scan
switchboard
switchboard-plug-desktop
switchboard-plug-locale
switchboard-plug-security-privacy
ttf-dejavu
ttf-droid
ttf-liberation
ttf-opensans
vala
wingpanel
wingpanel-indicator-datetime
wingpanel-indicator-power
wingpanel-indicator-session

## VirtualBox
virtualbox-guest-utils
virtualbox-guest-modules-arch

## AUR
ttf-raleway
gnome-settings-daemon-elementary
elementary-wallpapers-git
pantheon-default-settings
pantheon-session-git
switchboard-plug-elementary-tweaks-git
pantheon-screencast
pantheon-system-monitor-git
pantheon-mail-git
elementary-planner-git
EOT

rm -f ${PROFILE}/airootfs/etc/systemd/system/getty@tty1.service.d/autologin.conf # Remove autologin

# Enable our daemons
ln -s /lib/systemd/system/lightdm.service ${PROFILE}/airootfs/etc/systemd/system/display-manager.service
ln -s /lib/systemd/system/NetworkManager.service ${PROFILE}/airootfs/etc/systemd/system/multi-user.target.wants
ln -s /lib/systemd/system/cups.socket ${PROFILE}/airootfs/etc/systemd/system/sockets.target.wants
ln -s /lib/systemd/system/avahi-daemon.socket ${PROFILE}/airootfs/etc/systemd/system/sockets.target.wants
ln -s /lib/systemd/system/bluetooth.service ${PROFILE}/airootfs/etc/systemd/system/bluetooth.target.wants

# Build & bundle the disk image
mkdir ./out
mkdir /tmp/archiso-tmp
mkarchiso -v -w /tmp/archiso-tmp ${PROFILE}
rm -rf /tmp/archiso-tmp
mv ./out/cards-*.*.*-x86_64.iso ~
