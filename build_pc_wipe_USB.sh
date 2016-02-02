#!/bin/sh

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# This script creates a bootable Arch Linux USB drive on OS X systems.
# The Arch Linux live image is generated using Archiso and customized 
# to include the pc_wipe.sh script. After booting from the USB drive,
# the script can be found under ~/pc_wipe.sh.


# List of attached drives
DRIVE_LIST=$(diskutil list | grep /dev/disk)

# Locate attached USB drives
USB_COUNT=0
for DRIVE in $DRIVE_LIST ; do
	CURRENT_DRIVE=$(diskutil info $DRIVE | grep Protocol | grep USB | awk '{print $2}')
	if [[ "${CURRENT_DRIVE}" == "USB" ]] ; then
		((USB_COUNT++))
		TARGET=$(echo $DRIVE)
	fi
done

# This script will exit if there isn't only one USB drive attached
case "$USB_COUNT" in
	0)
	echo "\nUSB drive not detected.\n"
	exit 135
	;;
	1)
	echo "\nDetected USB drive $TARGET\n"
	;;
	*)
	echo "\nPlease make sure there's only one USB drive attached then run this script again.\n"
	exit 136
	;;
esac

# Display the target USB drive name, size, and partitions
diskutil info $TARGET | grep -A 14 "Device / Media Name:" | sed '/Volume\ Name/,/SMART\ Status/d' | head -n 4 | awk '$1=$1' | sed G
diskutil list $TARGET | tail -n +2

# Confirm to proceed with overwriting target USB drive
echo "\nWARNING: All data on the USB drive $TARGET will be erased. Type \"YES\" to continue.\n"
read CONTINUE
if [[ "${CONTINUE}" == "YES" ]] ; then
	diskutil unmountDisk $TARGET || {
		echo "Failed to unmount the target USB drive ${TARGET[$SELECT]}"
		exit 137
	}
	ISO_URL=$(curl -s https://api.github.com/repos/tristanthomas/pc_wipe/releases | grep browser_download_url | head -n 1 | cut -d '"' -f 4) || {
		echo "Failed to retrieve the ISO URL, please connect to the Internet then execute this script again."
		exit 138
	}
	ISO_FILENAME=$(echo $ISO_URL | awk -F '/' '{print $9}')
	echo "\nDownloading Arch Linux live image, $ISO_FILENAME...\n"
	curl -LO $ISO_URL || {
		echo "Failed to download the ISO file, please connect to the Internet then execute this script again."
		exit 139
	}
	TARGET_RDISK=$(echo $TARGET | sed 's/disk/rdisk/g')
	echo "\nCreating a bootable Arch Linux USB drive...\n"
	echo "To proceed, enter your password.\n"
	sudo dd if=$ISO_FILENAME of=$TARGET_RDISK bs=1m > /dev/null 2>&1 || {
		echo "Failed to create a bootable Arch Linux USB drive."
		exit 140
	}
	echo "Complete!\n"
	diskutil eject $TARGET || {
		echo "Failed to eject the USB drive $TARGET."
		exit 141
	}
	echo "\nClick Ignore if you see the prompt \"The disk you inserted was not readable by this computer.\""
else
	echo "\nA confirmation to proceed was not provided. The USB drive $TARGET was not modified.\n"
	exit 142
fi
