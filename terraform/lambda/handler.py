import json
import boto3

s3 = boto3.client("s3")

BUCKET = "enterprise-ai-document-agent-docs"


def lambda_handler(event, context):

    question = event.get(
        "question",
        "What documents are available?"
    )

    response = s3.list_objects_v2(
        Bucket=BUCKET,
        Prefix="documents/"
    )

    documents = []

    for item in response.get("Contents", []):

        key = item["Key"]

        if key.endswith("/"):
            continue

        documents.append(key)

    return {
        "statusCode": 200,
        "body": json.dumps({
            "question": question,
            "documents": documents
        })
    }