#!/bin/bash

source ./validate_HS_code.sh

print_help() {
    cat << EOF
Usage: $(basename "$0") [HS_CODE]

Description:
  This script runs the full trade flows analysis pipeline. It sets up the infrastructure
  using Terraform, downloads the required data, processes it, and uploads the results
  to Google Cloud Storage and BigQuery.

Positional Arguments:
  HS_CODE     Optional. One of the following: HS92, HS96, HS02, HS07, HS12, HS17, HS22
              Specifies the version of the Harmonized System (HS) classification to use.
              If not provided, defaults to: $DEFAULT_HS_CODE

Options:
  -h, --help  Show this help message and exit

Steps Performed:
  1. Set up infrastructure using Terraform (init, plan, apply).
  2. Download the data for the specified HS code.
  3. Unzip and upload the data to a Google Cloud Storage bucket.
  4. Convert the data to Parquet format using PySpark on Dataproc.
  5. Using PySpark, calculate total trade values by country and upload results to BigQuery.
  6. Using PySpark, calculate total trade values by country and HS code and upload results to BigQuery

Example:
  $(basename "$0") HS22
  $(basename "$0")             # Uses default: $DEFAULT_HS_CODE
EOF
}

# Check for help flag
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


# Step 1: Set up infrastructure using Terraform
cd ../terraform || exit 1
terraform init
terraform plan -out=tfplan
terraform apply -auto-approve tfplan
cd - || exit 1

# Step 2: Download the data for the specified HS code
bash download.sh "${HS_code}"

# Step 3: Unzip and upload the data to a Google Cloud Storage bucket
bash unzip_and_upload.sh "${HS_code}"

# Step 4: Convert the data to Parquet format using PySpark on Dataproc
gsutil cp convert_to_parquet.py gs://trade-flows-bucket/code/convert_to_parquet.py
bash run_convert_to_parquet.sh "${HS_code}"

# Step 5: Using PySpark, calculate total trade values by country and upload results to BigQuery
gsutil cp calculate_trade_per_country.py gs://trade-flows-bucket/code/calculate_trade_per_country.py
bash run_calculate_trade_per_country.sh "${HS_code}"

# Step 6: Using PySpark, calculate total trade values by country and HS code and upload results to BigQuery
gsutil cp calculate_trade_per_HS_code.py gs://trade-flows-bucket/code/calculate_trade_per_HS_code.py
bash run_calculate_trade_per_HS_code.sh "${HS_code}"
