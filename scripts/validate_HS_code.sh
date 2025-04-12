#!/bin/bash

DEFAULT_HS_CODE="HS17"

VALID_HS_CODES=(
    "HS92"
    "HS96"
    "HS02"
    "HS07"
    "HS12"
    "HS17"
    "HS22"
)

# Function to validate HS code provided as input
validate_HS_code() {
    local input="$1"

    for valid in "${VALID_HS_CODES[@]}"; do
        if [[ "$input" == "$valid" ]]; then
            echo "Valid HS code: $input"
            return 0
        fi
    done

    echo -e "The HS code provided is invalid: '$input'\nValid codes are: ${VALID_HS_CODES[*]}"
    exit 1
}

handle_HS_code() {
    local script_name=$(basename "$0")
    if [[ -z "$1" ]]; then
        echo -e "No HS code provided. Usage: $script_name <HSXX>\nUsing HS17 as default.\nValid codes are: ${VALID_HS_CODES[*]}"    
        HS_code="$DEFAULT_HS_CODE"
    else
        HS_code="$1"
        validate_HS_code "$HS_code"
    fi

    echo "$HS_code"

}
