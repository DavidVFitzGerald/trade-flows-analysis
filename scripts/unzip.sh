#!/bin/bash

source ./validate_HS_code.sh

HS_code=$(handle_HS_code "$1")
validation_status=$?

if [ "$validation_status" -ne 0 ]; then
  echo "$HS_code"
  exit 1
else
  HS_code=$(echo "$HS_code" | tail -n 1)
fi

CONFIG_FILE="config.json"

raw_dir=$(jq -r '.raw_dir' "$CONFIG_FILE")
staging_dir=$(jq -r '.staging_dir' "$CONFIG_FILE")

raw_dir="${raw_dir}/${HS_code}"
zip_file=$(find "${raw_dir}" -maxdepth 1 -type f -name "*.zip")

# Check if exactly one zip file exists
if [ -z "$zip_file" ]; then
  echo "No zip file found in ${raw_dir}. Exiting."
  exit 1
elif [ $(echo "$zip_file" | wc -l) -ne 1 ]; then
  echo "Multiple zip files found in ${raw_dir}. There should only be one. Exiting."
  exit 1
fi

# Unzip the file into the staging directory
echo "Unzipping ${zip_file} into ${staging_dir}"
staging_dir="${staging_dir}/${HS_code}"
rm -rf "${staging_dir}"; mkdir "${staging_dir}"
unzip -o "${zip_file}" -d "${staging_dir}"

if [ $? -eq 0 ]; then
  echo "Unzipping completed successfully."
else
  echo "An error occurred while unzipping. Exiting."
  exit 1
fi