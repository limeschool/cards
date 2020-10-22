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

# Add packages to our local repository (shared between host and profile)
cp -f ${PROFILE}/pacman.conf /etc
mkdir //.cache && chmod 777 //.cache # Since we can't run 'aur sync' as sudo, we have to make the cache directory manually
pacman -Rdd gsettings-desktop-schemas
su -s /bin/sh nobody -c "aur sync -d custom --root ${LOCAL_REPO} --no-confirm --noview \
ttf-raleway \
gnome-doc-utils \
libhandy1 \
pantheon-screencast \
yay \
whitesur-gtk-theme-git \
whitesur-icon-theme-git \
whitesur-cursor-theme-git \
gnome-shell-extension-dash-to-dock \
gnome-shell-extension-emoji-selector-git \
ttf-twemoji-color \
gtk-theme-elementary-git \
elementary-icon-theme-git \
pantheon-calculator-git \
pantheon-calendar-git \
pantheon-files-git \
pantheon-music-git \
pantheon-photos-git \
pantheon-screenshot-git \
pantheon-terminal-git \
pantheon-videos-git \
procs \
csview \
dust \
bottom \
tealdeer \
ox-git"

echo -e "LOCAL_REPO:\n---"
ls ${LOCAL_REPO}
echo "---"

# Add packages from Arch's repositories to our profile
tee -a ${PROFILE}/packages.x86_64 > /dev/null <<EOT
## Cards default packages
archlinux-appstream-data
bluez
bluez-utils
capnet-assist
contractor
cups
cups-pk-helper
dino
elementary-icon-theme-git #AUR
epiphany
file-roller
flatpak
gdm
geary
glfw-wayland
gnome-backgrounds
gnome-characters
gnome-control-center
gnome-disk-utility
gnome-keyring
gnome-shell
gnome-shell-extension-dash-to-dock #AUR
gnome-shell-extension-emoji-selector-git #AUR
gnome-shell-extensions
gnome-software
gnome-software-packagekit-plugin
gnome-system-monitor
gnome-tweaks
gnome-user-share
gnu-free-fonts
gtk-engine-murrine
gtk-theme-elementary-git #AUR
gtkspell3
gvfs
gvfs-afc
gvfs-gphoto2
gvfs-mtp
gvfs-nfs
gvfs-smb
intel-tbb
intel-ucode
libva
libva-mesa-driver
mesa
mutter
networkmanager
noto-fonts
noto-fonts-emoji
nvidia-dkms
orca
pacman-contrib
pantheon-calculator-git #AUR
pantheon-calendar-git #AUR
pantheon-code
pantheon-files-git #AUR
pantheon-music-git #AUR
pantheon-photos-git #AUR
pantheon-print
pantheon-screencast #AUR
pantheon-screenshot-git #AUR
pantheon-terminal-git #AUR
pantheon-videos-git #AUR
pulseaudio-bluetooth
qt5-svg
qt5-translations
qt5-wayland
rygel
sound-theme-elementary
tracker
tracker-miners
tracker3
tracker3-miners
ttf-dejavu
ttf-droid
ttf-hack
ttf-liberation
ttf-opensans
ttf-raleway #AUR
ttf-roboto-mono
ttf-twemoji-color #AUR
vala
vulkan-radeon
wayland
wayland-protocols
whitesur-cursor-theme-git #AUR
whitesur-gtk-theme-git #AUR
whitesur-icon-theme-git #AUR
wlc
xdg-user-dirs-gtk
xf86-input-libinput
xorg
xorg-drivers
xorg-server
xorg-server-xwayland
xorg-twm
xorg-xclock
xorg-xinit
xterm
yay #AUR

## Rust utilities
alacritty
bandwhich
bat
bottom #AUR
csview #AUR
dust #AUR
exa
fd
hyperfine
mdcat
ox-git #AUR
procs #AUR
ripgrep
sd
tealdeer #AUR
tokei

## VirtualBox
virtualbox-guest-utils
EOT

rm -f ${PROFILE}/airootfs/etc/systemd/system/getty@tty1.service.d/autologin.conf # Remove autologin

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

# Build & bundle the disk image
mkdir ./out
mkdir /tmp/archiso-tmp
mkarchiso -v -w /tmp/archiso-tmp ${PROFILE}
mv ./out/cards-*.*.*-x86_64.iso ~
