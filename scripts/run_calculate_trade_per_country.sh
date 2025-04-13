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

BUCKET_NAME="trade-flows-bucket"
BQ_DATASET_NAME="trade_flows_dataset"

gcloud dataproc jobs submit pyspark \
    --cluster=trade-flows-cluster \
    --properties='spark.driver.memory=4g,spark.executor.memory=4g' \
    --region=europe-west6 \
    gs://"${BUCKET_NAME}"/code/calculate_trade_per_country.py \
    -- \
      --HS_code="${HS_code}" \
      --bucket_name="${BUCKET_NAME}" \
      --bq_dataset_name="${BQ_DATASET_NAME}" \