# AWS Lambda Chromium Screenshot API

This project uses AWS Lambda with a Chromium layer to capture screenshots of a URL. Follow the steps below to set it up and deploy the code.

## Prerequisites

- AWS CLI is installed and configured
- S3 bucket exists for uploading Chromium layer
- Necessary IAM permissions to create layers and upload files to S3

## Setup Instructions

### Step 1: Set up Chromium Lambda Layer

Run the script to download or build the Chromium binary, upload it to S3, and create the Lambda layer.

```bash
chmod +x scripts/setup-chromium-layer.sh
./scripts/setup-chromium-layer.sh create
```

After successful execution, the ARN of the layer will be saved to `chromium-layer-arn.txt`. Use this ARN in the next step.

### Step 2: Update Serverless Configuration

Add the ARN from `chromium-layer-arn.txt` into your `serverless.yml` under the `functions.server.layers` section.

```yaml
functions:
  server:
    handler: src/index.handler
    layers:
      - arn:aws:lambda:<region>:<account-id>:layer:chromium:<version>
    events:
      - http:
          path: /
          method: ANY
          cors: true
      - http:
          path: /{proxy+}
          method: ANY
          cors: true
```

### Step 3: Deploy the Server

Deploy the code to AWS using the following command:

```bash
pnpm run deploy
```

### Step 4: Test the API

Call the `/screenshot` API to capture a screenshot of the provided URL and return it in an HTML response.

Example API call:

```
GET /screenshot?url=https://example.com
```

### Note

To remove the AWS Lambda layer, use the script:

```bash
./scripts/setup-chromium-layer.sh remove
```

You need to manually remove the browser file from the S3 bucket after deletion.
