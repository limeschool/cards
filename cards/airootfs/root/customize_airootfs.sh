#!/usr/bin/env bash
#
# SPDX-License-Identifier: GPL-3.0-or-later

set -e -u

# Warning: customize_airootfs.sh is deprecated! Support for it will be removed in a future archiso version.

sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
locale-gen

sed -i "s/#Server/Server/g" /etc/pacman.d/mirrorlist

# Hide unwanted app entries
tee -a /usr/share/applications/avahi-discover.desktop > /dev/null <<EOT
NoDisplay=true
EOT
tee -a /usr/share/applications/gda-browser-5.0.desktop > /dev/null <<EOT
NoDisplay=true
EOT
tee -a /usr/share/applications/gda-control-center-5.0.desktop > /dev/null <<EOT
NoDisplay=true
EOT
tee -a /usr/share/applications/lstopo.desktop > /dev/null <<EOT
NoDisplay=true
EOT
tee -a /usr/share/applications/onboard-settings.desktop > /dev/null <<EOT
NoDisplay=true
EOT
tee -a /usr/share/applications/onboard.desktop > /dev/null <<EOT
NoDisplay=true
EOT
tee -a /usr/share/applications/qv4l2.desktop > /dev/null <<EOT
NoDisplay=true
EOT
tee -a /usr/share/applications/qvidcap.desktop > /dev/null <<EOT
NoDisplay=true
EOT
tee -a /usr/share/applications/stoken-gui-small.desktop > /dev/null <<EOT
NoDisplay=true
EOT
tee -a /usr/share/applications/stoken-gui.desktop > /dev/null <<EOT
NoDisplay=true
EOT
tee -a /usr/share/applications/uxterm.desktop > /dev/null <<EOT
NoDisplay=true
EOT
tee -a /usr/share/applications/vim.desktop > /dev/null <<EOT
NoDisplay=true
EOT
tee -a /usr/share/applications/bssh.desktop > /dev/null <<EOT
NoDisplay=true
EOT
tee -a /usr/share/applications/bvnc.desktop > /dev/null <<EOT
NoDisplay=true
EOT
tee -a /usr/share/applications/cups.desktop > /dev/null <<EOT
NoDisplay=true
EOT
tee -a /usr/share/applications/xterm.desktop > /dev/null <<EOT
NoDisplay=true
EOT
tee -a /usr/share/applications/org.gnome.Extensions.desktop > /dev/null <<EOT
NoDisplay=true
EOT

# Remove unwanted session entries
rm -f /usr/share/xsessions/gnome-classic.desktop
rm -f /usr/share/xsessions/gnome-xorg.desktop

chmod -R 777 /usr/share/gnome-shell/extensions/ # Ensure extensions do not experience permissions errors
glib-compile-schemas /usr/share/glib-2.0/schemas/ # Compile w/ Cards' gschema.override

# Enable task completion notifications for pantheon-terminal
tee -a /etc/zsh/zshrc > /dev/null <<EOT
builtin . /usr/share/io.elementary.terminal/enable-zsh-completion-notifications || builtin true
EOT
