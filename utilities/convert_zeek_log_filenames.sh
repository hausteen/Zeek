#!/bin/bash

# Author: Austin Hunt
# Date: 12 July 2023
# Version: 1.1

# Purpose of the script:
# This script will change every colon to an underscore character
# in every log file name under every folder in the zeek logs folder
# excluding the folder named "current".
# This script forces Zeek log file names to
# have valid names on any operating system you use.
# Windows in particular doesn't allow colon (:) characters in filenames.

# Usage:
# Step 1: Make sure that you have write permissions on the files in 
#         the zeek logs folder. You probably need "root" 
#         if you aren't the "zeek" user.
# Step 2: Make the script executable (chmod +x convert_zeek_filenames.sh).
# Step 3: Run the script (./convert_zeek_filenames.sh)

os_name=$(grep -E "^ID=" /etc/os-release | cut -d "=" -f 2)

# This script is built for Debian, but the user can still run this if they choose to.
if [[ $os_name != "debian" ]]; then
    echo "This script was meant for Debian only. It may not work on your distro."
    while true; do
        read -r -p "Proceed anyway? [y/n]: " proceed_anyway_answer
        case $proceed_anyway_answer in
            [nN] | [nN][oO])
                exit
                ;;
            [yY] | [yY][eE][sS])
                break
                ;;
        esac
    done
fi

# Find the base zeek folder location
if [[ -d "/opt/zeek/" ]]; then
    zeek_base_folder="/opt/zeek"
elif [[ -d "/usr/local/zeek/" ]]; then
    zeek_base_folder="/usr/local/zeek"
fi

# Get the Zeek log folder from the zeekctl.cfg file
zeek_logs_folder=$(grep -E "LogDir\s?=" $zeek_base_folder/etc/zeekctl.cfg | grep -Eo "/.+" | sed -E "/\/$/! s/$/\//")
# Verify the zeek_logs_folder path. If its wrong, verify if the default logs folder location is there and use that instead.
if [[ ! -d $zeek_logs_folder ]]; then
	if [[ -d "$zeek_base_folder/logs/" ]]; then
		zeek_logs_folder="$zeek_base_folder/logs/"
	else
		echo "Can't find the zeek logs folder. Exiting."
		exit
	fi
fi

# Run a check to make sure the folder path has a trailing slash.
# We need it for the next command to work properly.
if [[ ! $zeek_logs_folder =~ /$ ]]; then
	echo "The folder path needs to have a trailing forward slash."
	exit
fi

# Loop through each of the folders under the logs folder
for i in $(ls -d $zeek_logs_folder*/);
do
	# Skip the "current" folder since the files are still being written to.
	if [[ $zeek_logs_folder"current/" == $i ]]; then
		continue
	fi
	cd $i
	echo "Editing folder: $i"
	# Edit each file name ending in .log.gz
	for j in $(ls *.log.gz);
	do
		new_name=$(echo $j | sed -E 's/:/_/g')
		mv -i $j $new_name
	done
done
