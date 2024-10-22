#!/bin/bash

# Function to handle errors
error_handler() {
    echo "An error occurred on line $1."
    exit 1
}

# Trap errors in the script
trap 'error_handler $LINENO' ERR
