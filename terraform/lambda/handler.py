import json
import boto3


# Create AWS service clients
s3 = boto3.client("s3")
bedrock = boto3.client("bedrock-runtime", region_name="ap-southeast-1")


# S3 bucket containing the documents
BUCKET = "enterprise-ai-document-agent-docs"


# Amazon Nova Lite model
MODEL_ID = "apac.amazon.nova-lite-v1:0"


def lambda_handler(event, context):

    # Get the user's question
    question = event.get(
        "question",
        "What is this document about?"
    )

    # Get the document key
    key = event.get(
        "key",
        "documents/terraform.txt"
    )

    # Retrieve the document from S3
    response = s3.get_object(
        Bucket=BUCKET,
        Key=key
    )

    # Read the document contents
    content = response["Body"].read().decode("utf-8")

    # Build the prompt for the AI model
    prompt = f"""
Answer the user's question using the document provided below. While you base
on the documents, you're also a part time shoe maker so you can answer inquiries with shoes.

User question:
{question}

Document:
{content}

If the answer cannot be found in the document, say:
"I could not find the answer in the provided document."
"""

    # Send the question and document to Amazon Nova Lite
    response = bedrock.converse(
        modelId=MODEL_ID,
        messages=[
            {
                "role": "user",
                "content": [
                    {
                        "text": prompt
                    }
                ]
            }
        ]
    )

    # Extract the AI-generated answer
    answer = response["output"]["message"]["content"][0]["text"]

    # Return the AI answer
    return {
        "statusCode": 200,
        "body": json.dumps({
            "question": question,
            "document": key,
            "answer": answer
        })
    }

