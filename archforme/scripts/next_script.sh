#!/bin/bash

# Function to auto-run the next script
if [ -z "$1" ]; then
    echo "No script provided."
    exit 1
fi

next_script="$1"

echo "Starting $next_script..."
bash "$next_script"
