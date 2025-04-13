#!/bin/bash

source ./validate_HS_code.sh

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
BUCKET_NAME="trade-flows-bucket"
gsutil -m cp "${csv_dir}/*.csv" "gs://${BUCKET_NAME}/csv/${HS_code}/"