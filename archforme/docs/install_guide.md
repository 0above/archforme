# Arch Linux Installation Guide

## Step 1: Boot from the USB
1. Connect to Wi-Fi using `iwctl`.
2. Clone the repository: `git clone https://github.com/0above/archformesetup.git`
3. Change to the directory: `cd archformesetup/archforme`
4. Start the installation by running: `./scripts/01_partition.sh`

## Step 2: Partition and Install the System
The script will automatically partition the disk, install the base system, and configure the system.

## Step 3: Configure the System
- Set up the network.
- Install Hyprland, Waybar, Wofi, and your chosen applications.

## Step 4: Set Up User Account
Create a user account with the script and complete the setup.

### Troubleshooting
In case of errors, refer to the error logs generated by the script or check the Arch Linux wiki.