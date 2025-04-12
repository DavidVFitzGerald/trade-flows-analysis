#!/bin/bash

print_help() {
    cat << EOF
Usage: $(basename "$0") [HS_CODE]

Description:
  This script downloads the data from the CEPII BACI database and unzips it. The data is available 
  for different versions  of the Harmonized System (HS), which is a classification system for goods. 
  The script checks the availability of the data for the current year and the previous year. If the 
  data for the current year is not available, it will download the data for the previous year.

Positional Arguments:
  HS_CODE     Optional. One of the following: HS92, HS96, HS02, HS07, HS12, HS17, HS22
              If not provided, defaults to: $DEFAULT_HS_CODE

Options:
  -h, --help  Show this help message and exit

Example:
  $(basename "$0") HS12
  $(basename "$0")             # Uses default: $DEFAULT_HS_CODE
EOF
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    print_help
    exit 0
fi


source ./validate_HS_code.sh

website_url="https://www.cepii.fr/DATA_DOWNLOAD/baci/data/BACI_"

HS_code=$(handle_HS_code "$1")
validation_status=$?

if [ "$validation_status" -ne 0 ]; then
  echo "$HS_code"
  exit 1
else
  HS_code=$(echo "$HS_code" | tail -n 1)
fi

url_prefix="${website_url}${HS_code}_V"

# Function to check if a URL is valid
check_url() {
    local url="$1"
    echo "Checking URL $url ..."
    
    # Check the HTTP response code
    http_code=$(curl -o /dev/null -sL --head -w "%{http_code}" "$url")

    if [[ "$http_code" -ge 200 && "$http_code" -lt 400 ]]; then
        echo "Valid URL: $url"
        return 0
    else
        echo "Invalid URL: $url (HTTP $http_code)"
        return 1
    fi
}

# Create list containing the current year and the previous year. In case the data is downloaded at the beginning of the year, before the new version of the data is available, the URL will contain the previous year.
current_year=$(date +%Y)
previous_year=$((current_year - 1))
years=(
    "$current_year"
    "$previous_year"
)

# List of URL suffixes to try. As updates to the data can be made, the URL ending might not be 01. The list of suffixes is based on the logic of URLs of the archived releases listed on https://www.cepii.fr/CEPII/en/bdd_modele/bdd_modele_item.asp?id=37.
url_suffixes=(
    "01"
    "01b"
    "01c"
    "02"
    "02b"
    "02c"
    "03"
    "03b"
    "03c"
)

# Try each URL suffix in order. If none of the suffixes work, it may be because the data for the current year is not available yet. In that case, the previous year is used.
for year in "${years[@]}"; do
    url_year="${url_prefix}${year}"
    for url_suffix in "${url_suffixes[@]}"; do
        url="${url_year}${url_suffix}.zip"
        if check_url "$url"; then
            echo "Downloading $url"
            filename=$(basename "$url")
            raw_dir="../data/raw/${HS_code}"
            mkdir -p ${raw_dir}
            zip_path="${raw_dir}/${filename}"
            wget ${url} -O ${zip_path}
            staging_dir="../data/staging/${HS_code}"
            mkdir -p ${staging_dir}
            unzip -o ${zip_path} -d ${staging_dir}
            exit 0
        fi
    done
done

# If none of the tested URLs are valid, exit
echo "None of the tested URLs are valid. No file was downloaded and unzipped. Exiting."
exit 1