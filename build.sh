#!/bin/bash
export HOME=~
export PROFILE=${HOME}/cards-profile
export LOCAL_REPO=${HOME}/local-repo
set +h
umask 0022 # Correct file permissions

pacman -Syu archiso git base-devel jq expac diffstat pacutils wget devtools curl --noconfirm --noprogressbar # Install packages we'll need to build

# Allow us to use a standard user account w/ password-less sudo privilege (for building AUR packages later)
tee -a /etc/sudoers > /dev/null <<EOT
nobody    ALL=(ALL) NOPASSWD:ALL
EOT

# Install aurutils for aurto
git clone https://aur.archlinux.org/aurutils.git
chmod 777 aurutils
cd aurutils
su -s /bin/sh nobody -c "makepkg -si --noconfirm --noprogressbar" # Make aurutils as a regular user
cd ../

# Install aurto to build our local repository from AUR packages
mkdir /.cargo
chmod -R 777 /.cargo
git clone https://aur.archlinux.org/aurto.git
chmod 777 aurto
cd aurto
su -s /bin/sh nobody -c "sudo makepkg -srci --noconfirm --noprogressbar" # Make aurutils as a regular user
cd ../

rm -f /etc/aurto/trusted-users # Don't prompt to install aurto packages

# Begin setting up our profile
cp -r /usr/share/archiso/configs/releng/ ${PROFILE}
cp -rf ./cards/. ${PROFILE}
mkdir ${LOCAL_REPO}
#repo-add ${LOCAL_REPO}/custom.db.tar.xz
chmod -R 777 ${LOCAL_REPO}

# Add repositories to our profile
tee -a ${PROFILE}/pacman.conf > /dev/null <<EOT
[aurto]
SigLevel = Optional TrustAll
Server = file://${LOCAL_REPO}
EOT

# Add packages to our local repository (shared between host and profile)
# 1. Add repositories to our host
tee -a /etc/pacman.conf > /dev/null <<EOT
[aurto]
SigLevel = Optional TrustAll
Server = file://${LOCAL_REPO}
EOT

# 2. Add our packages from the AUR
#su -s /bin/sh nobody -c "sudo aur sync -d custom --root ${LOCAL_REPO} --no-confirm --noview ttf-raleway"
#su -s /bin/sh nobody -c "sudo aur sync -d custom --root ${LOCAL_REPO} --no-confirm --noview gnome-settings-daemon-elementary"
#su -s /bin/sh nobody -c "sudo aur sync -d custom --root ${LOCAL_REPO} --no-confirm --noview elementary-wallpapers-git"
#su -s /bin/sh nobody -c "sudo aur sync -d custom --root ${LOCAL_REPO} --no-confirm --noview pantheon-default-settings"
#su -s /bin/sh nobody -c "sudo aur sync -d custom --root ${LOCAL_REPO} --no-confirm --noview pantheon-session-git"
#su -s /bin/sh nobody -c "sudo aur sync -d custom --root ${LOCAL_REPO} --no-confirm --noview switchboard-plug-elementary-tweaks-git"
#su -s /bin/sh nobody -c "sudo aur sync -d custom --root ${LOCAL_REPO} --no-confirm --noview pantheon-screencast"
#su -s /bin/sh nobody -c "sudo aur sync -d custom --root ${LOCAL_REPO} --no-confirm --noview pantheon-system-monitor-git"
#su -s /bin/sh nobody -c "sudo aur sync -d custom --root ${LOCAL_REPO} --no-confirm --noview pantheon-mail-git"
#su -s /bin/sh nobody -c "sudo aur sync -d custom --root ${LOCAL_REPO} --no-confirm --noview elementary-planner-git"
su -s /bin/sh nobody -c "aurto add ttf-raleway"
su -s /bin/sh nobody -c "aurto add gnome-settings-daemon-elementary"
su -s /bin/sh nobody -c "aurto add elementary-wallpapers-git"
su -s /bin/sh nobody -c "aurto add pantheon-default-settings"
su -s /bin/sh nobody -c "aurto add pantheon-session-git"
su -s /bin/sh nobody -c "aurto add switchboard-plug-elementary-tweaks-git"
su -s /bin/sh nobody -c "aurto add pantheon-screencast"
su -s /bin/sh nobody -c "aurto add pantheon-system-monitor-git"
su -s /bin/sh nobody -c "aurto add pantheon-mail-git"
su -s /bin/sh nobody -c "aurto add elementary-planner-git"

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
lightdm-gtk-greeter
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
EOT

rm -f ${PROFILE}/airootfs/etc/systemd/system/getty@tty1.service.d/autologin.conf # Remove autologin

# Enable our daemons
ln -s /usr/lib/systemd/system/lightdm.service ${PROFILE}/airootfs/etc/systemd/system/display-manager.service
ln -s /usr/lib/systemd/system/NetworkManager.service ${PROFILE}/airootfs/etc/systemd/system/multi-user.target.wants
ln -s /usr/lib/systemd/system/cups.socket ${PROFILE}/airootfs/etc/systemd/system/sockets.target.wants
ln -s /usr/lib/systemd/system/avahi-daemon.socket ${PROFILE}/airootfs/etc/systemd/system/sockets.target.wants
ln -s /usr/lib/systemd/system/bluetooth.service ${PROFILE}/airootfs/etc/systemd/system/bluetooth.target.wants

# Build & bundle the disk image
mkdir ./out
mkdir /tmp/archiso-tmp
mkarchiso -v -w /tmp/archiso-tmp ${PROFILE}
mv ./out/cards-*.*.*-x86_64.iso ~
