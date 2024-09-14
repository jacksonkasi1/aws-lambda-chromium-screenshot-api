#!/bin/bash

# Stop the script if any command fails
set -e

# Variables
BUCKET_NAME="serverless-chromium-bucket"
LAYER_NAME="chromium"
VERSION_NUMBER="127.0.0"
S3_KEY="chromiumLayers/chromium${VERSION_NUMBER}.zip"
LAYER_FILE="chromium-layer-arn.txt"
CHROMIUM_ZIP="chromium-v${VERSION_NUMBER}.zip"
CHROMIUM_LAYER_URL="https://github.com/Sparticuz/chromium/releases/download/v${VERSION_NUMBER}/chromium-v${VERSION_NUMBER}-layer.zip"
REGION="ap-south-1"
RUNTIME="nodejs20.x"
ARCHITECTURE="x86_64"

# Check if necessary tools are installed
check_tools() {
    command -v curl >/dev/null 2>&1 || { echo >&2 "Error: curl is not installed. Please install it."; exit 1; }
    command -v aws >/dev/null 2>&1 || { echo >&2 "Error: AWS CLI is not installed. Please install it."; exit 1; }
}

# Check if the S3 bucket exists
check_s3_bucket() {
    if ! aws s3 ls "s3://${BUCKET_NAME}" >/dev/null 2>&1; then
        echo "Error: The specified S3 bucket (${BUCKET_NAME}) does not exist. Please create it first."
        exit 1
    fi
}

# Function to create the layer
create_layer() {
    check_tools
    check_s3_bucket

    # Step 1: Download or build Chromium layer
    if [ ! -f "${CHROMIUM_ZIP}" ]; then
        echo "Downloading Chromium layer..."
        curl -L -o "${CHROMIUM_ZIP}" "${CHROMIUM_LAYER_URL}" || { echo "Error: Failed to download Chromium."; exit 1; }
    fi

    # Step 2: Upload Chromium zip to S3
    echo "Uploading Chromium layer to S3..."
    aws s3 cp "${CHROMIUM_ZIP}" "s3://${BUCKET_NAME}/${S3_KEY}" --region "${REGION}" || { echo "Error: Failed to upload to S3."; exit 1; }

    # Step 3: Create the Lambda layer
    echo "Creating Lambda Layer..."
    LAYER_ARN=$(aws lambda publish-layer-version \
        --layer-name "${LAYER_NAME}" \
        --description "Chromium v${VERSION_NUMBER}" \
        --content "S3Bucket=${BUCKET_NAME},S3Key=${S3_KEY}" \
        --compatible-runtimes "${RUNTIME}" \
        --compatible-architectures "${ARCHITECTURE}" \
        --region "${REGION}" \
        --query 'LayerVersionArn' --output text) || { echo "Error: Failed to create Lambda layer."; exit 1; }

    # Step 4: Save Layer ARN to file
    echo "Saving Layer ARN to ${LAYER_FILE}..."
    echo "${LAYER_ARN}" > "${LAYER_FILE}"

    echo "Layer created successfully! Layer ARN: ${LAYER_ARN}"
}

# Function to remove the layer
remove_layer() {
    if [ ! -f "${LAYER_FILE}" ]; then
        echo "Layer ARN file not found!"
        exit 1
    fi

    LAYER_ARN=$(cat "${LAYER_FILE}")
    echo "Removing Lambda Layer with ARN: ${LAYER_ARN}..."

    # Extract layer name and version from ARN
    LAYER_NAME=$(echo "${LAYER_ARN}" | cut -d: -f7)
    LAYER_VERSION=$(echo "${LAYER_ARN}" | cut -d: -f8)

    # Delete the Lambda layer version
    aws lambda delete-layer-version --layer-name "${LAYER_NAME}" --version-number "${LAYER_VERSION}" --region "${REGION}" || { echo "Error: Failed to delete Lambda layer."; exit 1; }

    echo "Layer version ${LAYER_VERSION} deleted."

    # Remove the saved ARN file
    rm -f "${LAYER_FILE}"
    echo "Layer ARN file removed."
}

# Function to print usage
print_usage() {
    echo "Usage: $0 {create|remove}"
    echo "Commands:"
    echo "  create  - Create and publish the Chromium Lambda layer"
    echo "  remove  - Remove the Chromium Lambda layer and its ARN file"
}

# Main script execution
if [ "$#" -ne 1 ]; then
    print_usage
    exit 1
fi

if [ "$1" == "create" ]; then
    create_layer
elif [ "$1" == "remove" ]; then
    remove_layer
else
    print_usage
    exit 1
fi
