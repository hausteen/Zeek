#!/bin/bash

# Author: Austin Hunt
# Date: 24 June 2023
# Version: 1.0

# Purpose of the script:
# This script is to make it so that all the log file names
# have valid names on any operating system you use.
# Windows in particular doesn't allow colon (:) characters in filenames.
# This script will change every colon to an underscore character
# in every log file name under every folder in the logs folder
# excluding the folder named "current".

# Usage:
# Step 1: Edit the "zeek_logs_folder" variable down below to match 
#         the folder path to the zeek logs for your zeek install.
# Step 2: Make the script executable (chmod +x filename).
# Step 3: Make sure that you have write permissions on the files in 
#         the zeek logs folder. You probably need "root" 
#         if you aren't the "zeek" user.
# Step 4: Run the script (./filename)

# Put in the folder location where the Zeek logs are.
# This is the top level log folder. 
# You should see yyyy-mm-dd folders in this logs folder.
zeek_logs_folder="/opt/zeek/logs/"

# Run a check to make sure the path exists
if [[ ! -d $zeek_logs_folder ]]; then
	echo "The folder path does not exist."
	exit
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
		mv $j $new_name
	done
done
