#!/bin/bash

# Script: loadenvkey.sh
# Purpose: Read contents of a file and export to ENCRYPTION_KEY environment variable

# Get the file path from argument or use default
FILE_PATH=/run/secrets/locket/encryption_key

# Check if file exists
if [[ ! -f "$FILE_PATH" ]]; then
    echo "Error: File '$FILE_PATH' not found."
    echo "Usage: source loadenvkey.sh [path-to-key-file]"
    return 1 2>/dev/null || exit 1
fi

# Read file contents and export to ENCRYPTION_KEY
export ENCRYPTION_KEY=$(cat "$FILE_PATH")

# Verify export was successful
if [[ -z "$ENCRYPTION_KEY" ]]; then
    echo "Error: File '$FILE_PATH' is empty."
    return 1 2>/dev/null || exit 1
fi

echo "✓ ENCRYPTION_KEY loaded from '$FILE_PATH'"
