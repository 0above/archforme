#!/bin/bash

set -e  # Stop on any errors

# Error handler
source ./scripts/error_handler.sh

echo "Partitioning the disk..."

# Select the disk (you can improve this by listing disks dynamically)
DISK="/dev/sda"

# Ask the user to confirm the correct disk
read -p "Please confirm the disk to partition (default: /dev/sda): " input_disk
DISK="${input_disk:-$DISK}"

# Create partitions (UEFI, root, swap, and home)
echo "Creating partitions on $DISK..."
parted --script "$DISK" mklabel gpt \
  mkpart ESP fat32 1MiB 513MiB \
  set 1 boot on \
  mkpart primary ext4 513MiB 40.5GiB \
  mkpart primary linux-swap 40.5GiB 44.5GiB \
  mkpart primary ext4 44.5GiB 100%

# Format the partitions
echo "Formatting partitions..."
mkfs.fat -F32 "${DISK}1"  # EFI partition
mkfs.ext4 "${DISK}2"  # Root partition
mkswap "${DISK}3"  # Swap partition
mkfs.ext4 "${DISK}4"  # Home partition

# Mount the partitions
echo "Mounting partitions..."
mount "${DISK}2" /mnt  # Root
mkdir /mnt/boot
mount "${DISK}1" /mnt/boot  # EFI
mkdir /mnt/home
mount "${DISK}4" /mnt/home  # Home
swapon "${DISK}3"  # Enable swap

echo "Partitions created and mounted successfully."

# Move to the next script
./scripts/next_script.sh ./scripts/02_install.sh
