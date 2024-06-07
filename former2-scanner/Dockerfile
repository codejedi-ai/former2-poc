FROM node:14.8.0-buster-slim

WORKDIR /former2

# Install dependencies and Former2
RUN apt-get update && \
    npm install -g former2

# Environment variables for mount directory and AWS region
ENV MOUNT_DIR=/data
# default AWS region us-east-1
# ENV AWS_REGION=us-east-1
# ENV aws_access_key_id = XXXX
# ENV aws_secret_access_key = XXXXXX

# Create the directory to ensure it exists
RUN mkdir -p ${MOUNT_DIR}
WORKDIR ${MOUNT_DIR}

# Copy the entrypoint script
COPY entrypoint.sh /entrypoint.sh

# Make the entrypoint script executable
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

# docker run -v "$(pwd)":/data former3