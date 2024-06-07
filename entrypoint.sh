#!/bin/bash

# Run Former2 command with parameters from environment variables
former2 generate --output-terraform "${MOUNT_DIR}/terraform.hcl" --region ${AWS_REGION}

# Explicitly exit to ensure the container stops
exit 0