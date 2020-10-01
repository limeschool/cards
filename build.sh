#!/bin/bash
export PROFILE=~/cards-profile
set +h
umask 0022 # Correct file permissions

pacman -Syu archiso --noconfirm
cp -r /usr/share/archiso/configs/releng/ ${PROFILE}

sudo tee -a ${PROFILE}/packages.x86_64 > /dev/null <<EOT
mesa
xf86-video-amdgpu
xf86-video-intel
nvidia
nvidia-utils
pantheon
EOT

echo -e "packages.x86_64:\n---"
echo "$(<${PROFILE}/packages.x86_64)"
echo "---"

mkdir ./out
mkdir /tmp/archiso-tmp
mkarchiso -v -w /tmp/archiso-tmp ${PROFILE}
rm -rf /tmp/archiso-tmp
mv ./out/archlinux-*-x86_64.iso ~/cards.iso
