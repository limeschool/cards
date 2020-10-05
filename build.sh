#!/bin/bash
export HOME=~
export PROFILE=${HOME}/cards-profile
export LOCAL_REPO=${HOME}/local-repo
set +h
umask 0022 # Correct file permissions
systemd-machine-id-setup # Prevents errors when building AUR packages

pacman -Syu archiso git base-devel jq expac diffstat pacutils wget devtools libxslt cmake \
intltool gtk-doc gobject-introspection gnome-common polkit dbus-glib gtk3 glade meson vala \
xorg-server-xvfb light-locker ufw go --noconfirm --noprogressbar # Install packages we'll need to build

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
pantheon-session-git \
pantheon-default-settings \
pantheon-dock-git \
pantheon-screencast \
pantheon-system-monitor-git \
elementary-planner-git \
clipped-git \
gamehub-git \
ideogram-git \
agenda-git \
yay"

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

## Display & Misc. Desktop Environment
lightdm
nvidia-dkms
vulkan-radeon
qt5-svg
qt5-translations
gnome-disk-utility
yay

## VirtualBox
virtualbox-guest-utils

## Pantheon
pantheon-session-git
pantheon-default-settings
file-roller
pantheon-dock-git
pantheon-screencast
pantheon-system-monitor-git
elementary-planner-git
clipped-git
gamehub-git
ideogram-git
agenda-git
lightdm
contractor
lightdm-pantheon-greeter
sound-theme-elementary
switchboard
pantheon-geoclue2-agent
pantheon-polkit-agent
pantheon-print
capnet-assist
epiphany
pantheon-calculator
pantheon-calendar
pantheon-camera
pantheon-code
pantheon-files
pantheon-music
pantheon-photos
pantheon-screenshot
pantheon-shortcut-overlay
pantheon-terminal
pantheon-videos
simple-scan
pantheon-applications-menu
wingpanel-indicator-datetime
wingpanel-indicator-session
wingpanel-indicator-bluetooth
wingpanel-indicator-keyboard
wingpanel-indicator-network
wingpanel-indicator-nightlight
wingpanel-indicator-notifications
wingpanel-indicator-power
wingpanel-indicator-sound
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
switchboard-plug-display
switchboard-plug-sharing
light-locker
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
mv ./out/cards-*.*.*-x86_64.iso ~
