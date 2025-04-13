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

bash download.sh "${HS_code}"
bash unzip_and_upload.sh "${HS_code}"
gsutil cp convert_to_parquet.py gs://trade-flows-bucket/code/convert_to_parquet.py
bash run_convert_to_parquet.sh "${HS_code}"
gsutil cp calculate_trade_per_country.py gs://trade-flows-bucket/code/calculate_trade_per_country.py
bash run_calculate_trade_per_country.sh "${HS_code}"
gsutil cp calculate_trade_per_HS_code.py gs://trade-flows-bucket/code/calculate_trade_per_HS_code.py
bash run_calculate_trade_per_HS_code.sh "${HS_code}"