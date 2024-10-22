#!/bin/bash

set -e  # Stop on any errors

source ./scripts/error_handler.sh

echo "Mounting necessary partitions..."
# Ensure root partition is mounted to /mnt
mount /dev/sdXn /mnt  # Replace /dev/sdXn with your root partition
# Mount other partitions if you have them (e.g., /boot, /home)
# mount /dev/sdY1 /mnt/boot  # Example for boot

# Install base system, Linux kernel, firmware, and essential packages
echo "Installing the base system..."
pacstrap /mnt base linux linux-firmware

# Generate an fstab file
echo "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# Copy the necessary scripts to the new environment
echo "Copying configuration scripts to the new system..."
mkdir -p /mnt/root/archformesetup/scripts
cp ./scripts/*.sh /mnt/root/archformesetup/scripts

# Change root into the new system and run the next script within the chroot
echo "Entering the new system and starting configuration..."
arch-chroot /mnt /bin/bash -c "/root/archformesetup/scripts/03_configure.sh"

echo "Base system installed and configured."
