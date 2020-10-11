#!/usr/bin/env bash
#
# SPDX-License-Identifier: GPL-3.0-or-later

set -e -u

# Warning: customize_airootfs.sh is deprecated! Support for it will be removed in a future archiso version.

sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
locale-gen

sed -i "s/#Server/Server/g" /etc/pacman.d/mirrorlist

# Remove unwanted program icons
rm -f /usr/share/applications/avahi-discover.desktop
rm -f /usr/share/applications/gda-browser-5.0.desktop
rm -f /usr/share/applications/gda-control-center-5.0.desktop
rm -f /usr/share/applications/lftp.desktop
rm -f /usr/share/applications/lstopo.desktop
rm -f /usr/share/applications/onboard-settings.desktop
rm -f /usr/share/applications/onboard.desktop
rm -f /usr/share/applications/qv4l2.desktop
rm -f /usr/share/applications/qvidcap.desktop
rm -f /usr/share/applications/stoken-gui-small.desktop
rm -f /usr/share/applications/stoken-gui.desktop
rm -f /usr/share/applications/uxterm.desktop
rm -f /usr/share/applications/vim.desktop

# Replace GTK settings files
rm -f /usr/share/gtk-2.0/gtkrc
rm -f /usr/share/gtk-3.0/settings.ini
mv /usr/share/gtk-2.0/gtkrc.cards /usr/share/gtk-2.0/gtkrc
mv /usr/share/gtk-3.0/settings.ini.cards /usr/share/gtk-3.0/settings.ini

gsettings set org.gnome.desktop.wm.preferences button-layout ‘:minimize,maximize,close’ # Set GNOME titlebar buttons
