#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="cards"
iso_label="CARDS_$(date +%Y%m)"
iso_publisher="Cards"
iso_application="Cards Live Environment"
iso_version="$(date +%Y.%m.%d)"
install_dir="cards"
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito' 'uefi-x64.systemd-boot.esp' 'uefi-x64.systemd-boot.eltorito')
arch="x86_64"
pacman_conf="pacman.conf"
