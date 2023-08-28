#!/bin/bash
. ./admin-openrc.sh

#Get all filenames form that folder
FOLDER_PATH="/home/ahv"

# Iterate through files in the folder
for file in "$FOLDER_PATH"/*; do
    # Check if the entry is a file
    if [[ -f "$file" ]]; then
        # Extract and print the filename
        filename=$(basename "$file")

        # Get the filesize in bytes
        filesize_bytes=$(stat -c "%s" "$file")

        # Convert filesize to GB and round to nearest whole digit
        filesize_gb=$(echo "scale=0; $filesize_bytes / (1024*1024*1024)" | bc)


        # Print the filename and filesize
        echo "File: $filename, Size: $filesize_gb GB"


        # Create a volume in openstack
        openstack volume create --size $filesize_gb --availability-zone chur $filename --bootable

        # Get Volume ID
        VOLUME_ID=$(openstack volume show $filename -c id -f value)

        # Remove the volume in Ceph
        rbd rm openstack_vms/volume-$VOLUME_ID

        # Copy the qcow2 from here to Ceph
        rbd import $FOLDER_PATH/$filename openstack_vms/volume-$VOLUME_ID

    fi
done
