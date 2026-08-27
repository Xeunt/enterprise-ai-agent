import json
import boto3

s3 = boto3.client("s3")

BUCKET = "enterprise-ai-document-agent-docs"


def lambda_handler(event, context):

    key = event.get(
        "key",
        "documents/terraform.txt"
    )

    response = s3.get_object(
        Bucket=BUCKET,
        Key=key
    )

    content = response["Body"].read().decode("utf-8")

    return {
        "statusCode": 200,
        "body": json.dumps({
            "document": key,
            "content": content
        })
    }