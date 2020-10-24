#!/bin/bash
export HOME=~
export PROFILE=${HOME}/cards-profile
export LOCAL_REPO=${HOME}/local-repo
set +h
umask 0022 # Correct file permissions
systemd-machine-id-setup # Prevents errors when building AUR packages

pacman -Syu archiso git base-devel jq expac diffstat pacutils wget devtools libxslt cmake \
intltool gtk-doc gobject-introspection gnome-common polkit dbus-glib libhandy \
meson vala gnome-settings-daemon libgee --noconfirm --noprogressbar # Install packages we'll need to build

# Allow us to use a standard user account w/ password-less sudo privilege (for building AUR packages later)
tee -a /etc/sudoers > /dev/null <<EOT
nobody    ALL=(ALL) NOPASSWD:ALL
EOT

# Install aurutils to build our local repository from AUR packages
git clone https://aur.archlinux.org/aurutils.git
chmod 777 aurutils
cd aurutils
su -s /bin/sh nobody -c "makepkg -si --noconfirm --noprogressbar" # Make aurutils as a regular user
cd ../

# Begin setting up our profile
cp -r /usr/share/archiso/configs/releng/ ${PROFILE}
cp -rf ./cards/. ${PROFILE}
mkdir ${LOCAL_REPO}
repo-add ${LOCAL_REPO}/custom.db.tar.xz
chmod -R 777 ${LOCAL_REPO}
sed -i -e "s?~/local-repo?${LOCAL_REPO}?" ${PROFILE}/pacman.conf

# Import free wallpapers
git clone https://github.com/elementary/wallpapers.git
mkdir -p ${PROFILE}/usr/share/backgrounds/gnome
cp -rf ./wallpapers/backgrounds/. ${PROFILE}/usr/share/backgrounds/gnome

# Add packages to our local repository (shared between host and profile)
cp -f ${PROFILE}/pacman.conf /etc
mkdir //.cache && chmod 777 //.cache # Since we can't run 'aur sync' as sudo, we have to make the cache directory manually
pacman -Rdd gsettings-desktop-schemas
su -s /bin/sh nobody -c "aur sync -d custom --root ${LOCAL_REPO} --no-confirm --noview \
ttf-raleway \
ttf-twemoji-color \
libhandy1 \
pantheon-screencast \
yay \
dashbinsh \
ion-git \
gdm-plymouth \
gnome-shell-extension-dash-to-dock \
gnome-shell-extension-emoji-selector-git \
elementary-icon-theme-git \
pantheon-calculator-git \
pantheon-calendar-git \
pantheon-files-git \
pantheon-music-git \
pantheon-photos-git \
pantheon-screenshot-git \
pantheon-terminal-git \
pantheon-videos-git \
grub-theme-vimix-git \
plymouth-theme-colorful-sliced-git"

echo -e "LOCAL_REPO:\n---"
ls ${LOCAL_REPO}
echo "---"

# Add packages from Arch's repositories to our profile
tee -a ${PROFILE}/packages.x86_64 > /dev/null <<EOT
## System
archlinux-appstream-data
bandwhich
bat
bluez
bluez-utils
capnet-assist
contractor
cups
cups-pk-helper
dash
dashbinsh
dino
elementary-icon-theme-git
epiphany
exa
fd
file-roller
flatpak
gdm-plymouth
geary
glfw-wayland
gnome-backgrounds
gnome-characters
gnome-control-center
gnome-disk-utility
gnome-keyring
gnome-shell
gnome-shell-extension-dash-to-dock
gnome-shell-extension-emoji-selector-git
gnome-shell-extensions
gnome-software
gnome-software-packagekit-plugin
gnome-system-monitor
gnome-tweaks
gnome-user-share
gnu-free-fonts
gtk-engine-murrine
gtkspell3
gvfs
gvfs-afc
gvfs-gphoto2
gvfs-mtp
gvfs-nfs
gvfs-smb
hyperfine
intel-tbb
intel-ucode
inter-font
ion-git
libva
libva-mesa-driver
mdcat
mesa
mutter
networkmanager
noto-fonts
noto-fonts-emoji
nvidia
nvidia-dkms
orca
pacman-contrib
pantheon-calculator-git
pantheon-calendar-git
pantheon-code
pantheon-files-git
pantheon-music-git
pantheon-photos-git
pantheon-print
pantheon-screencast
pantheon-screenshot-git
pantheon-terminal-git
pantheon-videos-git
pulseaudio-bluetooth
qt5-svg
qt5-translations
qt5-wayland
ripgrep
rygel
sd
sound-theme-elementary
tokei
tracker
tracker-miners
tracker3
tracker3-miners
ttf-dejavu
ttf-droid
ttf-hack
ttf-liberation
ttf-opensans
ttf-raleway
ttf-roboto-mono
ttf-twemoji-color
vala
vulkan-radeon
wayland
wayland-protocols
weston
wlc
xdg-user-dirs-gtk
xf86-input-libinput
xf86-video-amdgpu
xf86-video-ati
xf86-video-fbdev
xf86-video-intel
xf86-video-nouveau
xf86-video-vesa
xorg
xorg-drivers
xorg-server
xorg-server-xwayland
xorg-twm
xorg-xclock
xorg-xinit
xterm
yay

## Boot
#plymouth-theme-cubes-git
#plymouth-theme-green-blocks-git
#plymouth-theme-lone-git
#plymouth-theme-rings-git
grub-theme-vimix-git
plymouth-theme-colorful-sliced-git

## VirtualBox
linux-headers
virtualbox-guest-dkms
virtualbox-guest-utils
EOT

rm -f ${PROFILE}/airootfs/etc/systemd/system/getty@tty1.service.d/autologin.conf # Remove autologin
chmod +x ${PROFILE}/airootfs/usr/bin/weston-session # Set weston-session as executable
ln -sfT dash ${PROFILE}/airootfs/usr/bin/sh # Set dash as the shell at /usr/bin/sh

# Enable our daemons
mkdir -p ${PROFILE}/airootfs/etc/modules-load.d
mkdir -p ${PROFILE}/airootfs/etc/systemd/system/bluetooth.target.wants
mkdir -p ${PROFILE}/airootfs/etc/systemd/system/multi-user.target.wants
mkdir -p ${PROFILE}/airootfs/etc/systemd/system/printer.target.wants
mkdir -p ${PROFILE}/airootfs/etc/systemd/system/sockets.target.wants
ln -s /lib/modules-load.d/virtualbox-guest-dkms.conf ${PROFILE}/airootfs/etc/modules-load.d
ln -s /lib/systemd/system/NetworkManager.service ${PROFILE}/airootfs/etc/systemd/system/multi-user.target.wants
ln -s /lib/systemd/system/avahi-daemon.socket ${PROFILE}/airootfs/etc/systemd/system/sockets.target.wants
ln -s /lib/systemd/system/bluetooth.service ${PROFILE}/airootfs/etc/systemd/system/bluetooth.target.wants
ln -s /lib/systemd/system/cups.service ${PROFILE}/airootfs/etc/systemd/system/printer.target.wants
ln -s /lib/systemd/system/cups.socket ${PROFILE}/airootfs/etc/systemd/system/sockets.target.wants
ln -s /lib/systemd/system/gdm.service ${PROFILE}/airootfs/etc/systemd/system/display-manager.service

# Set Plymouth theme
mkdir -p ${PROFILE}/airootfs/etc/alternatives
mkdir -p ${PROFILE}/airootfs/usr/share/plymouth/themes
ln -s  /usr/share/plymouth/themes/colorful_sliced/colorful_sliced.plymouth ${PROFILE}/airootfs/etc/alternatives/default.plymouth
ln -s  /etc/alternatives/default.plymouth ${PROFILE}/airootfs/usr/share/plymouth/themes/default.plymouth

# Build & bundle the disk image
mkdir ./out
mkdir /tmp/archiso-tmp
mkarchiso -v -w /tmp/archiso-tmp ${PROFILE}
mv ./out/cards-*.*.*-x86_64.iso ~
