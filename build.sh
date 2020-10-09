#!/bin/bash
export HOME=~
export PROFILE=${HOME}/cards-profile
export LOCAL_REPO=${HOME}/local-repo
set +h
umask 0022 # Correct file permissions
systemd-machine-id-setup # Prevents errors when building AUR packages

pacman -Syu archiso git base-devel jq expac diffstat pacutils wget devtools libxslt cmake \
intltool gtk-doc gobject-introspection gnome-common polkit dbus-glib --noconfirm --noprogressbar # Install packages we'll need to build

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
elementary-wallpapers-git \
gnome-doc-utils \
libhandy1 \
pantheon-default-settings \
pantheon-session-git \
switchboard-plug-elementary-tweaks-git \
pantheon-screencast \
pantheon-system-monitor-git \
clipped-git \
gamehub-git \
ideogram-git \
yay \
whitesur-gtk-theme-git \
whitesur-icon-theme-git \
whitesur-cursor-theme-git \
gnome-shell-extension-dash-to-dock"

echo -e "LOCAL_REPO:\n---"
ls ${LOCAL_REPO}
echo "---"

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

## Display & Utilities
nvidia-dkms
vulkan-radeon
qt5-svg
qt5-translations
gnome-disk-utility
gnome-tweaks

## Desktop Environment
capnet-assist
contractor
cups
cups-pk-helper
elementary-icon-theme
elementary-wallpapers
epiphany
file-roller
gala
gnome
gnu-free-fonts
gtk-engine-murrine
gtk-theme-elementary
gtkspell3
gvfs
gvfs-afc
gvfs-mtp
gvfs-nfs
gvfs-smb
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
switchboard-plug-a11y
switchboard-plug-about
switchboard-plug-applications
switchboard-plug-bluetooth
switchboard-plug-datetime
switchboard-plug-desktop
switchboard-plug-display
switchboard-plug-keyboard
switchboard-plug-locale
switchboard-plug-mouse-touchpad
switchboard-plug-network
switchboard-plug-notifications
switchboard-plug-online-accounts
switchboard-plug-parental-controls
switchboard-plug-power
switchboard-plug-printers
switchboard-plug-security-privacy
switchboard-plug-sharing
switchboard-plug-sound
switchboard-plug-user-accounts
ttf-dejavu
ttf-droid
ttf-liberation
ttf-opensans
vala
wingpanel
wingpanel-indicator-datetime
wingpanel-indicator-session
wingpanel-indicator-bluetooth
wingpanel-indicator-keyboard
wingpanel-indicator-network
wingpanel-indicator-nightlight
wingpanel-indicator-notifications
wingpanel-indicator-power
wingpanel-indicator-sound

## VirtualBox
virtualbox-guest-utils

## AUR
whitesur-gtk-theme-git
whitesur-icon-theme-git
whitesur-cursor-theme-git
ttf-raleway
elementary-wallpapers-git
pantheon-default-settings
pantheon-session-git
switchboard-plug-elementary-tweaks-git
pantheon-screencast
pantheon-system-monitor-git
#pantheon-mail-git # AUR package depends on "libhandy-1", not "libhandy1", which exists
clipped-git
ideogram-git
yay
gnome-shell-extension-dash-to-dock
EOT

rm -f ${PROFILE}/airootfs/etc/systemd/system/getty@tty1.service.d/autologin.conf # Remove autologin

# Enable our daemons
mkdir -p ${PROFILE}/airootfs/etc/systemd/system/multi-user.target.wants
mkdir -p ${PROFILE}/airootfs/etc/systemd/system/sockets.target.wants
mkdir -p ${PROFILE}/airootfs/etc/systemd/system/bluetooth.target.wants
mkdir -p ${PROFILE}/airootfs/etc/modules-load.d
ln -s /lib/systemd/system/gdm.service ${PROFILE}/airootfs/etc/systemd/system/display-manager.service
ln -s /lib/systemd/system/NetworkManager.service ${PROFILE}/airootfs/etc/systemd/system/multi-user.target.wants
ln -s /lib/systemd/system/cups.socket ${PROFILE}/airootfs/etc/systemd/system/sockets.target.wants
ln -s /lib/systemd/system/avahi-daemon.socket ${PROFILE}/airootfs/etc/systemd/system/sockets.target.wants
ln -s /lib/systemd/system/bluetooth.service ${PROFILE}/airootfs/etc/systemd/system/bluetooth.target.wants
ln -s /lib/modules-load.d/virtualbox-guest-dkms.conf ${PROFILE}/airootfs/etc/modules-load.d

# Build & bundle the disk image
mkdir ./out
mkdir /tmp/archiso-tmp
mkarchiso -v -w /tmp/archiso-tmp ${PROFILE}
mv ./out/cards-*.*.*-x86_64.iso ~
