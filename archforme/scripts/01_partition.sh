#!/bin/bash

set -e  # Stop on any errors

# Error handler
source ./scripts/error_handler.sh

# ANSI color codes for formatting
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
NC="\033[0m"  # No color

clear  # Clear the terminal for a fresh start

# Title
printf "${CYAN}==================== Arch Linux Disk Partitioning Script ====================${NC}\n\n"

echo "Scanning your system for disk and specs..."

# Find the primary disk dynamically
DISK=$(lsblk -dpno name,size | grep -E "sd|nvme|vd" | head -n 1 | awk '{print $1}')

# Get the total size of the disk in GiB
total_size=$(parted -s "$DISK" unit GiB print | grep "^Disk" | awk '{print $3}' | sed 's/GiB//')

# Display detected disk info
printf "${YELLOW}Detected Disk:${NC} ${DISK} (${total_size} GiB)\n\n"

# Gather hardware info to make recommendations
RAM=$(free -g | awk '/^Mem:/{print $2}')
CPU=$(lscpu | grep 'Model name' | awk -F: '{print $2}' | xargs)

# System info
printf "${YELLOW}System Info:${NC}\n"
printf "  - CPU: ${CYAN}${CPU}${NC}\n"
printf "  - RAM: ${CYAN}${RAM}GB${NC}\n\n"

# Recommendations for partition sizes
printf "${YELLOW}Recommended partition sizes based on your system:${NC}\n"
if [ "$RAM" -lt 4 ]; then
    printf "  - Root partition: ${CYAN}20 GiB${NC} (minimal setup)\n"
    printf "  - Swap partition: ${CYAN}2 GiB${NC} (for low RAM)\n"
else
    printf "  - Root partition: ${CYAN}40 GiB${NC} (recommended for desktops)\n"
    printf "  - Swap partition: ${CYAN}${RAM} GiB${NC} (equal to RAM)\n"
fi
printf "  - Home partition: ${CYAN}Remaining space${NC} for user data\n\n"

# Prompt user for partition sizes
read -p "Enter the size for the root partition (default: 40 GiB): " root_size
root_size="${root_size:-40}"

read -p "Enter the size for the swap partition (default: $RAM GiB): " swap_size
swap_size="${swap_size:-$RAM}"

# Calculate remaining space for home partition
home_size=$((total_size - root_size - swap_size - 1))  # 1 GiB for EFI

if [ "$home_size" -le 0 ]; then
    printf "${RED}Error:${NC} The sizes you entered exceed available disk space.\n"
    exit 1
fi

# Display partition sizes
printf "\n${GREEN}Partition Layout:${NC}\n"
printf "  - Root partition size: ${CYAN}${root_size} GiB${NC}\n"
printf "  - Swap partition size: ${CYAN}${swap_size} GiB${NC}\n"
printf "  - Home partition size: ${CYAN}${home_size} GiB${NC}\n\n"

# Encryption Option for Root or Home
printf "${YELLOW}Would you like to encrypt the root or home partition?${NC} (Enter 'root', 'home', or 'none')\n"
read encryption_choice

# Partition creation with LUKS encryption if selected
printf "\n${CYAN}Creating partitions on ${DISK}...${NC}\n"

# Create partitions
parted --script "$DISK" mklabel gpt \
  mkpart ESP fat32 1MiB 513MiB \
  set 1 boot on \
  mkpart primary ext4 513MiB "$((513 + root_size))GiB" \
  mkpart primary linux-swap "$((513 + root_size))GiB" "$((513 + root_size + swap_size))GiB" \
  mkpart primary ext4 "$((513 + root_size + swap_size))GiB" "$total_size GiB"

# Format EFI partition
mkfs.fat -F32 "${DISK}1"

# Apply encryption if selected
if [ "$encryption_choice" == "root" ]; then
    printf "${GREEN}Encrypting root partition...${NC}\n"
    cryptsetup luksFormat "${DISK}2"
    cryptsetup open "${DISK}2" cryptroot
    mkfs.ext4 /dev/mapper/cryptroot
    mount /dev/mapper/cryptroot /mnt
elif [ "$encryption_choice" == "home" ]; then
    printf "${GREEN}Encrypting home partition...${NC}\n"
    mkfs.ext4 "${DISK}2"
    mount "${DISK}2" /mnt
    cryptsetup luksFormat "${DISK}4"
    cryptsetup open "${DISK}4" crypthome
    mkfs.ext4 /dev/mapper/crypthome
    mkdir /mnt/home
    mount /dev/mapper/crypthome /mnt/home
else
    mkfs.ext4 "${DISK}2"
    mkfs.ext4 "${DISK}4"
    mount "${DISK}2" /mnt
    mkdir /mnt/home
    mount "${DISK}4" /mnt/home
fi

# Format and enable swap
mkswap "${DISK}3"
swapon "${DISK}3"

printf "\n${GREEN}Partitions created and mounted successfully.${NC}\n\n"

# Move to the next script
./scripts/next_script.sh ./scripts/02_install.sh
