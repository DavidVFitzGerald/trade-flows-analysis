#!/bin/bash

source ./validate_HS_code.sh

HS_code=$(handle_HS_code "$1")
validation_status=$?
script_name="$2"

if [ "$validation_status" -ne 0 ]; then
  echo "${HS_code}"
  exit 1
else
  HS_code=$(echo "${HS_code}" | tail -n 1)
fi


CONFIG_FILE="config.json"
raw_dir=$(jq -r '.raw_dir' "$CONFIG_FILE")
bucket_name=$(jq -r '.bucket_name' "$CONFIG_FILE")
bq_dataset_name=$(jq -r '.bq_dataset_name' "$CONFIG_FILE")
cluster_name=$(jq -r '.cluster_name' "$CONFIG_FILE")

gcloud dataproc jobs submit pyspark \
    --cluster="${cluster_name}" \
    --properties='spark.driver.memory=4g,spark.executor.memory=4g' \
    --region=europe-west6 \
    gs://"${bucket_name}"/code/"${script_name}" \
    -- \
      --HS_code="${HS_code}" \
      --bucket_name="${bucket_name}" \
      --bq_dataset_name="${bq_dataset_name}" \