#!/bin/bash
export PROFILE=~/cards-profile
set +h
umask 0022 # Correct file permissions

pacman -Syu archiso --noconfirm
cp -r /usr/share/archiso/configs/releng/ ${PROFILE}
cp -rf ./custom/. ${PROFILE}

tee -a ${PROFILE}/packages.x86_64 > /dev/null <<EOT
xorg
xorg-xinit
mesa
gtk-engine-murrine
gtkspell3
lightdm-gtk-greeter
qt5-svg
qt5-wayland
qt5-translations
vala
pantheon
switchboard-plug-desktop
switchboard-plug-locale
switchboard-plug-security-privacy
gnome-disk-utility
EOT

echo -e "packages.x86_64:\n---"
echo "$(<${PROFILE}/packages.x86_64)"
echo "---"

mkdir ./out
mkdir /tmp/archiso-tmp
mkarchiso -v -w /tmp/archiso-tmp ${PROFILE}
rm -rf /tmp/archiso-tmp
mv ./out/archlinux-*-x86_64.iso ~/cards.iso
