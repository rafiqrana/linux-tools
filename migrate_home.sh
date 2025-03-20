#!/bin/bash

# Script to migrate the existing /home directory to a new NVMe partition
# Author: Your Name
# Date: YYYY-MM-DD
# Version: 1.0

set -e  # Exit immediately if a command exits with a non-zero status

# Function to display usage
usage() {
    echo "Usage: $0 -d <nvme_partition>"
    echo "Example: $0 -d /dev/nvme0n1p2"
    exit 1
}

# Parse command-line options
while getopts ":d:" opt; do
    case ${opt} in
        d )
            NVME_PARTITION=$OPTARG
            ;;
        \? )
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
        : )
            echo "Option -$OPTARG requires an argument." >&2
            usage
            ;;
    esac
done

# Check if NVME_PARTITION is set
if [ -z "$NVME_PARTITION" ]; then
    echo "Error: NVMe partition not specified!"
    usage
fi

# Check if the specified partition exists
if [ ! -b "$NVME_PARTITION" ]; then
    echo "Error: Specified partition $NVME_PARTITION does not exist!"
    exit 1
fi

# Confirm with the user
echo "You are about to migrate /home to $NVME_PARTITION."
read -rp "Are you sure you want to proceed? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
    echo "Operation aborted."
    exit 1
fi

# Step 1: Backup fstab
echo "Backing up /etc/fstab..."
sudo cp /etc/fstab /etc/fstab.backup

# Step 2: Format the new partition as ext4 (WARNING: This erases all data!)
echo "Formatting $NVME_PARTITION as ext4..."
sudo mkfs.ext4 "$NVME_PARTITION"

# Step 3: Mount the new partition temporarily
MOUNT_POINT="/mnt/new_home"
sudo mkdir -p "$MOUNT_POINT"
sudo mount "$NVME_PARTITION" "$MOUNT_POINT"

# Step 4: Copy existing /home data using rsync
echo "Copying /home data to the new partition..."
sudo rsync -aAXv /home/ "$MOUNT_POINT/"

# Step 5: Update fstab
UUID=$(blkid -s UUID -o value "$NVME_PARTITION")
echo "Updating /etc/fstab with the new partition..."
echo "# New /home partition" | sudo tee -a /etc/fstab
echo "UUID=$UUID  /home  ext4  defaults  0  2" | sudo tee -a /etc/fstab

# Step 6: Unmount old /home and mount the new one
echo "Unmounting /home and switching to the new partition..."
sudo umount /home || echo "Old /home is already unmounted."
sudo mount "$NVME_PARTITION" /home

# Step 7: Verify migration
echo "Verifying the migration..."
ls /home

echo "Migration completed successfully!"
echo "A reboot is recommended to ensure all changes take effect."
read -rp "Would you like to reboot now? (yes/no): " REBOOT
if [[ "$REBOOT" == "yes" ]]; then
    sudo reboot
else
    echo "Please reboot your system manually when convenient."
fi
