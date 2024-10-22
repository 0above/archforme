#!/bin/bash

set -e  # Stop on any errors

source ./scripts/error_handler.sh

echo "Configuring the system..."

# Set up time zone
ln -sf /usr/share/zoneinfo/Region/City /etc/localtime
hwclock --systohc

# Localization
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Network setup
echo "archlinux" > /etc/hostname
cat <<EOF > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   archlinux.localdomain   archlinux
EOF

# Install bootloader (GRUB)
echo "Installing GRUB..."
pacman -S --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Install Hyprland and other apps
echo "Installing Hyprland and apps..."
pacman -S --noconfirm hyprland waybar wofi brave-bin vscodium discord

echo "System configuration complete."

# Move to the next script
./scripts/next_script.sh ./scripts/04_user_setup.sh
