#!/bin/bash

source ./validate_HS_code.sh

print_help() {
    cat << EOF
Usage: $(basename "$0") [HS_CODE]

Description:
  This script unzips the zip file for the specified Harmonized System (HS) code
  and uploads the extracted CSV files to a Google Cloud Storage (GCS) bucket.

Positional Arguments:
  HS_CODE     Optional. One of the following: HS92, HS96, HS02, HS07, HS12, HS17, HS22
              Specifies the version of the Harmonized System (HS) classification to use.
              If not provided, defaults to: $DEFAULT_HS_CODE

Options:
  -h, --help  Show this help message and exit

Example:
  $(basename "$0") HS22
  $(basename "$0")             # Uses default: $DEFAULT_HS_CODE
EOF
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    print_help
    exit 0
fi


HS_code=$(handle_HS_code "$1")
validation_status=$?

if [ "$validation_status" -ne 0 ]; then
  echo "${HS_code}"
  exit 1
else
  HS_code=$(echo "${HS_code}" | tail -n 1)
fi

CONFIG_FILE="config.json"

raw_dir=$(jq -r '.raw_dir' "$CONFIG_FILE")
csv_dir=$(jq -r '.csv_dir' "$CONFIG_FILE")

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
echo "Unzipping ${zip_file} into ${csv_dir}"
csv_dir="${csv_dir}/${HS_code}"
rm -rf "${csv_dir}"; mkdir "${csv_dir}"
unzip -o "${zip_file}" -d "${csv_dir}"

if [ $? -eq 0 ]; then
  echo "Unzipping completed successfully."
else
  echo "An error occurred while unzipping. Exiting."
  exit 1
fi

# Upload the CSV files to the GCS bucket.
CONFIG_FILE="config.json"
bucket_name=$(jq -r '.bucket_name' "$CONFIG_FILE")
gsutil -m cp "${csv_dir}/*.csv" "gs://${bucket_name}/csv/${HS_code}/"