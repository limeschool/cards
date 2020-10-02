#!/bin/bash
export PROFILE=~/cards-profile
set +h
umask 0022 # Correct file permissions

pacman -Syu archiso --noconfirm
cp -r /usr/share/archiso/configs/releng/ ${PROFILE}
cp -rf ./cards/. ${PROFILE}

tee -a ${PROFILE}/packages.x86_64 > /dev/null <<EOT
xorg
xorg-drivers
xorg-server
xorg-xinit
xf86-input-libinput
xterm
lightdm
mesa
gtk-engine-murrine
gtkspell3
qt5-svg
qt5-wayland
qt5-translations
vala
pantheon
lightdm-pantheon-greeter
switchboard-plug-desktop
switchboard-plug-locale
switchboard-plug-security-privacy
gnome-disk-utility
virtualbox-guest-utils
EOT

echo -e "packages.x86_64:\n---"
echo "$(<${PROFILE}/packages.x86_64)"
echo "---"

rm -f ${PROFILE}/airootfs/etc/systemd/system/getty@tty1.service.d/autologin.conf
ln -s /lib/systemd/system/lightdm.service ${PROFILE}/airootfs/etc/systemd/system/display-manager.service

mkdir ./out
mkdir /tmp/archiso-tmp
mkarchiso -v -w /tmp/archiso-tmp ${PROFILE}
rm -rf /tmp/archiso-tmp
mv ./out/cards-*.*.*-x86_64.iso ~
