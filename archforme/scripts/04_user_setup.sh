#!/bin/bash

set -e  # Stop on any errors

source ./scripts/error_handler.sh

echo "Setting up user account..."

# Create a new user
read -p "Enter the username: " username
useradd -m -G wheel,audio,video,input "$username"
passwd "$username"

# Enable sudo for the user
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

echo "User $username created and configured."

# Move to the next script
./scripts/next_script.sh ./scripts/error_handler.sh
