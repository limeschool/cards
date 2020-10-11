#!/usr/bin/env bash
#
# SPDX-License-Identifier: GPL-3.0-or-later

set -e -u

# Warning: customize_airootfs.sh is deprecated! Support for it will be removed in a future archiso version.

sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
locale-gen

sed -i "s/#Server/Server/g" /etc/pacman.d/mirrorlist

# Remove unwanted app entries
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
rm -f /usr/share/applications/bssh.desktop
rm -f /usr/share/applications/bvnc.desktop
rm -f /usr/share/applications/cups.desktop
rm -f /usr/share/applications/xterm.desktop
rm -f /usr/share/applications/org.gnome.Extensions.desktop

# Genericize app entries
rm -f /usr/share/applications/com.github.cassidyjames.ideogram.desktop
rm -f /usr/share/applications/com.github.davidmhewitt.clipped.desktop
rm -f /usr/share/applications/geary-autostart.desktop
rm -f /usr/share/applications/org.gnome.Cheese.desktop
rm -f /usr/share/applications/org.gnome.Geary.desktop
rm -f /usr/share/applications/im.dino.Dino.desktop
mv /usr/share/applications/com.github.cassidyjames.ideogram.desktop.cards /usr/share/applications/com.github.cassidyjames.ideogram.desktop
mv /usr/share/applications/com.github.davidmhewitt.clipped.desktop.cards /usr/share/applications/com.github.davidmhewitt.clipped.desktop
mv /usr/share/applications/geary-autostart.desktop.cards /usr/share/applications/geary-autostart.desktop
mv /usr/share/applications/org.gnome.Cheese.desktop.cards /usr/share/applications/org.gnome.Cheese.desktop
mv /usr/share/applications/org.gnome.Geary.desktop.cards /usr/share/applications/org.gnome.Geary.desktop
mv /usr/share/applications/im.dino.Dino.desktop.cards /usr/share/applications/im.dino.Dino.desktop

# Remove unwanted session entries
rm -f /usr/share/xsessions/gnome-classic.desktop
rm -f /usr/share/xsessions/gnome-xorg.desktop

# Replace GTK settings files
rm -f /usr/share/gtk-2.0/gtkrc
rm -f /usr/share/gtk-3.0/settings.ini
mv /usr/share/gtk-2.0/gtkrc.cards /usr/share/gtk-2.0/gtkrc
mv /usr/share/gtk-3.0/settings.ini.cards /usr/share/gtk-3.0/settings.ini

chmod -R 777 /usr/share/gnome-shell/extensions/ # Ensure extensions do not experience permissions errors
#gsettings set org.gnome.desktop.wm.preferences button-layout ':close,maximize,minimize' # Set GNOME titlebar buttons
#gsettings set org.gnome.mutter center-new-windows 'true' # Center new windows
#gsettings set org.gnome.desktop.interface gtk-theme "WhiteSur-dark" # Set GTK theme
#gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur-dark' # Set icon theme
#gsettings set org.gnome.desktop.interface cursor-theme 'WhiteSur-cursors' # Set mouse cursor theme
#gsettings set org.gnome.desktop.sound theme-name 'elementary' # Set sound theme
#gsettings set org.gnome.shell enabled-extensions "['dash-to-dock@micxgx.gmail.com']" # Enable dock
#gsettings set org.gnome.shell.extensions.dash-to-dock dock-position BOTTOM # Move dock to bottom of screen
#gsettings set org.gnome.shell.extensions.dash-to-dock autohide true # Autohide the dock when it interferes with a window
#gsettings set org.gnome.shell.extensions.dash-to-dock apply-custom-theme true # Theme the dock using the GTK theme
#gsettings set org.gnome.shell.extensions.dash-to-dock multi-monitor true # Place the dock on all monitors
#gsettings set org.gnome.shell favorite-apps "['org.gnome.Epiphany.desktop', 'io.elementary.files.desktop', 'org.gnome.Software.desktop', 'io.elementary.music.desktop', 'org.gnome.Cheese.desktop', 'io.elementary.photos.desktop', 'im.dino.Dino.desktop', 'gnome-control-center.desktop']"
glib-compile-schemas /usr/share/glib-2.0/schemas/ # Compile w/ Cards' gschema.override

# Enable task completion notifications for pantheon-terminal
tee -a /etc/zsh/zshrc > /dev/null <<EOT
builtin . /usr/share/io.elementary.terminal/enable-zsh-completion-notifications || builtin true
EOT
