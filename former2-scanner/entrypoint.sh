#!/bin/bash
# Ensure the AWS credentials directory exists
mkdir -p /root/.aws
# echo putting in the credentials
echo "Putting in the credentials"
# Write credentials to the /root/.aws/credentials file using environment variables
cat <<EOT > /root/.aws/credentials
[default]
aws_access_key_id = $YOUR_ACCESS_KEY_ID
aws_secret_access_key = $YOUR_SECRET_ACCESS_KEY
EOT
# echo credentials file created
echo "Credentials file created"
# Secure the credentials file
chmod 600 /root/.aws/credentials
# echo the search tag
echo "Search tag is: ${SEARCH_FILTER}"
# Run Former2 command with parameters from environment variables
# former2 generate --output-terraform "${MOUNT_DIR}/terraform.hcl" --region ${AWS_REGION}
former2 generate --output-terraform "tf.hcl" --region ${AWS_REGION} --search-filter ${SEARCH_FILTER}
# Explicitly exit to ensure the container stops
exit 0