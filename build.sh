#!/bin/bash
export PROFILE=~/cards-profile
set +h
umask 0022 # Correct file permissions

pacman -Syu archiso --noconfirm
cp -r /usr/share/archiso/configs/releng/ ${PROFILE}
echo "packages.x86_64:\n---"
echo "$(<${PROFILE}/packages.x86_64)"
echo "---"
mkdir ./out
mkdir /tmp/archiso-tmp
mkarchiso -v -w /tmp/archiso-tmp ${PROFILE}
rm -rf /tmp/archiso-tmp
mv ./out/archlinux.*.iso ~/cards.iso
