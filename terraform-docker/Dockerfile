FROM alpine:latest

# Install Terraform
ENV TERRAFORM_VERSION=1.2.9

RUN apk add --update git bash wget unzip && \
    wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/bin && \
    rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    terraform -v

WORKDIR /data

CMD ["terraform"]