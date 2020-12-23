#!/usr/bin/env bash
#
# SPDX-License-Identifier: GPL-3.0-or-later

set -e -u

# Warning: customize_airootfs.sh is deprecated! Support for it will be removed in a future archiso version.

sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
locale-gen

sed -i "s/#Server/Server/g" /etc/pacman.d/mirrorlist

# Remove unwanted session entries
rm -f /usr/share/xsessions/gnome-classic.desktop
rm -f /usr/share/xsessions/gnome-xorg.desktop

chmod -R 777 /usr/share/gnome-shell/extensions/ # Ensure extensions do not experience permissions errors
glib-compile-schemas /usr/share/glib-2.0/schemas/ # Compile w/ Cards' gschema.override
