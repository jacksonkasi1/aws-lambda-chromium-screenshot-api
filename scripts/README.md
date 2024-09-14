# AWS Lambda Chromium Layer Setup Script

This guide explains how to use the `setup-chromium-layer.sh` script to manage Chromium as an AWS Lambda layer. The script handles downloading or building the Chromium binary, uploading it to an S3 bucket, creating the Lambda layer, and removing the layer when necessary.

## Prerequisites

Before running the script, ensure the following:

1. **AWS CLI** is installed and configured with the necessary permissions to:
   - Upload files to S3.
   - Create and delete Lambda layers.

   If you haven't installed the AWS CLI, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html).

2. **S3 Bucket** exists where the Chromium layer will be uploaded. You can create a new S3 bucket using the AWS CLI:

   ```bash
   aws s3 mb s3://your-bucket-name
   ```

3. **Make the Script Executable**:
   Ensure that the script is executable by running:

   ```bash
   chmod +x setup-chromium-layer.sh
   ```

## Usage

The `setup-chromium-layer.sh` script provides two main functionalities:

- **Create the Chromium Lambda Layer**
- **Remove the Chromium Lambda Layer**

### 1. Create the Chromium Lambda Layer

To create the Chromium Lambda layer:

```bash
./setup-chromium-layer.sh create
```

This command will:

- Download the pre-built Chromium layer (or build it if required).
- Upload the Chromium ZIP file to the specified S3 bucket.
- Publish the Chromium Lambda layer to AWS Lambda.
- Save the ARN of the Lambda layer in a file named `chromium-layer-arn.txt`.

#### Example Output

```bash
Downloading Chromium layer...
Uploading Chromium layer to S3...
Creating Lambda Layer...
Saving Layer ARN to chromium-layer-arn.txt...
Layer created successfully! Layer ARN: arn:aws:lambda:your-region:your-account-id:layer:chromium:1
```

### 2. Remove the Chromium Lambda Layer

To remove the previously created Lambda layer:

```bash
./setup-chromium-layer.sh remove
```

This command will:

- Remove the Lambda layer version using the ARN saved in `chromium-layer-arn.txt`.
- Delete the `chromium-layer-arn.txt` file from your local directory.

#### Example Output

```bash
Removing Lambda Layer with ARN: arn:aws:lambda:your-region:your-account-id:layer:chromium:1...
Layer version 1 deleted.
Layer ARN file removed.
```

### 3. Commands Overview

- **`create`**:
  - Downloads or builds the Chromium Lambda layer.
  - Uploads the layer to an S3 bucket.
  - Publishes the Lambda layer.
  - Saves the ARN in `chromium-layer-arn.txt`.

- **`remove`**:
  - Deletes the Lambda layer using the ARN from `chromium-layer-arn.txt`.
  - Removes the `chromium-layer-arn.txt` file.

## Script Details

The `setup-chromium-layer.sh` script automates the creation and deletion of a Chromium AWS Lambda layer. It uses the Sparticuz Chromium package, which is optimized for AWS Lambda environments.

### Configuration Variables

The script uses the following environment variables:

- **`BUCKET_NAME`**: The S3 bucket where the layer ZIP file is uploaded.
- **`LAYER_NAME`**: The name of the Lambda layer (default is `chromium`).
- **`VERSION_NUMBER`**: The version number of Chromium (e.g., `127`).
- **`S3_KEY`**: The S3 object key for the uploaded ZIP file.
- **`REGION`**: AWS region (e.g., `us-east-1`).
- **`RUNTIME`**: The AWS Lambda runtime (e.g., `nodejs18.x`).
- **`ARCHITECTURE`**: Lambda architecture (e.g., `x86_64`).

### Example Script Code (`setup-chromium-layer.sh`)

```bash
#!/bin/bash

# Variables
BUCKET_NAME="your-chromium-bucket"
LAYER_NAME="chromium"
VERSION_NUMBER="127"
S3_KEY="chromiumLayers/chromium${VERSION_NUMBER}.zip"
LAYER_FILE="chromium-layer-arn.txt"
CHROMIUM_ZIP="chromium-v${VERSION_NUMBER}.zip"
CHROMIUM_LAYER_URL="https://github.com/Sparticuz/chromium/releases/download/v${VERSION_NUMBER}.0/chromium-v${VERSION_NUMBER}.0-layer.zip"
REGION="ap-south-1"
RUNTIME="nodejs18.x"
ARCHITECTURE="x86_64"

# Create the Lambda Layer
create_layer() {
    if [ ! -f "${CHROMIUM_ZIP}" ]; then
        echo "Downloading Chromium layer..."
        wget -O "${CHROMIUM_ZIP}" "${CHROMIUM_LAYER_URL}"
    fi

    echo "Uploading Chromium layer to S3..."
    aws s3 cp "${CHROMIUM_ZIP}" "s3://${BUCKET_NAME}/${S3_KEY}" --region "${REGION}"

    echo "Creating Lambda Layer..."
    LAYER_ARN=$(aws lambda publish-layer-version \
        --layer-name "${LAYER_NAME}" \
        --description "Chromium v${VERSION_NUMBER}" \
        --content "S3Bucket=${BUCKET_NAME},S3Key=${S3_KEY}" \
        --compatible-runtimes "${RUNTIME}" \
        --compatible-architectures "${ARCHITECTURE}" \
        --region "${REGION}" \
        --query 'LayerVersionArn' --output text)

    echo "Saving Layer ARN to ${LAYER_FILE}..."
    echo "${LAYER_ARN}" > "${LAYER_FILE}"
    echo "Layer created successfully! Layer ARN: ${LAYER_ARN}"
}

# Remove the Lambda Layer
remove_layer() {
    if [ ! -f "${LAYER_FILE}" ]; then
        echo "Layer ARN file not found!"
        exit 1
    fi

    LAYER_ARN=$(cat "${LAYER_FILE}")
    echo "Removing Lambda Layer with ARN: ${LAYER_ARN}..."

    LAYER_NAME=$(echo "${LAYER_ARN}" | cut -d: -f7)
    LAYER_VERSION=$(echo "${LAYER_ARN}" | cut -d: -f8)

    aws lambda delete-layer-version --layer-name "${LAYER_NAME}" --version-number "${LAYER_VERSION}" --region "${REGION}"

    rm -f "${LAYER_FILE}"
    echo "Layer version ${LAYER_VERSION} deleted."
}

# Print script usage
print_usage() {
    echo "Usage: $0 {create|remove}"
    echo "Commands:"
    echo "  create  - Create and publish the Chromium Lambda layer"
    echo "  remove  - Remove the Chromium Lambda layer and its ARN file"
}

# Main script
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
```

## Notes

- **Layer ARN**: The ARN of the created layer is saved to `chromium-layer-arn.txt`. Keep this file safe if you plan to use the layer in multiple Lambda functions.
- **Layer Deletion**: Ensure that you delete the layer if it's no longer needed, using the `remove` command.
