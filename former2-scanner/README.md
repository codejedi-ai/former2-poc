# Run 
docker build -t former3 .
docker run -d -it --name former-3-run --mount type=bind,source="$(pwd)"/data,target=/data -e AWS_REGION=us-east-1 former3


docker build -t former3 .
docker run -d -it --name former-3-run --mount type=bind,source="$(pwd)"/data,target=/data former3

# the docker file would also run with the environment variables

# ENV AWS_REGION=us-east-1
# ENV aws_access_key_id = XXXX
# ENV aws_secret_access_key = XXXXXX

