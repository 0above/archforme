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

# Get the total size of the disk in GiB
total_size=$(parted -s "$DISK" unit GiB print | grep "^Disk" | awk '{print $3}' | sed 's/GiB//')

echo "Total size of $DISK: $total_size GiB"

# Recommendations for partition sizes
echo "Recommended partition sizes:"
echo "  - Root partition: 20-40 GiB (for minimal setups), 40-100 GiB (for desktop environments with many applications)"
echo "  - Swap partition: 2-8 GiB (depends on RAM size; equal to RAM is a common rule of thumb)"
echo "  - Home partition: Use remaining space for user data"

# Prompt user for sizes
echo "Enter the size for the root partition (default: 40 GiB):"
read -p "Size in GiB: " root_size
root_size="${root_size:-40}"

echo "Enter the size for the swap partition (default: 4 GiB):"
read -p "Size in GiB: " swap_size
swap_size="${swap_size:-4}"

# Calculate remaining size for home partition
home_size=$((total_size - root_size - swap_size - 1))  # 1 GiB for EFI

if [ $home_size -le 0 ]; then
    echo "Error: The sizes you entered exceed the available disk space."
    exit 1
fi

echo "Root partition size: $root_size GiB"
echo "Swap partition size: $swap_size GiB"
echo "Home partition size: $home_size GiB"

# Create partitions (UEFI, root, swap, and home)
echo "Creating partitions on $DISK..."
parted --script "$DISK" mklabel gpt \
  mkpart ESP fat32 1MiB 513MiB \
  set 1 boot on \
  mkpart primary ext4 513MiB "$((513 + root_size))GiB" \
  mkpart primary linux-swap "$((513 + root_size))GiB" "$((513 + root_size + swap_size))GiB" \
  mkpart primary ext4 "$((513 + root_size + swap_size))GiB" "$total_size GiB"

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
