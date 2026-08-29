import json
import os
import boto3

# The secret key set by Terraform (see lambda.tf -> environment block)
API_KEY = os.environ.get("API_KEY")

# Create AWS service clients
s3 = boto3.client("s3")

bedrock = boto3.client(
    "bedrock-runtime",
    region_name="ap-southeast-1"
)


# S3 bucket containing the documents
BUCKET = "enterprise-ai-document-agent-docs"


# Amazon Nova Lite inference profile
MODEL_ID = "apac.amazon.nova-lite-v1:0"


# Documents the agent is allowed to retrieve
DOCUMENTS = {
    "menu": "documents/menu.txt",
    "company": "documents/company.txt",
    "policies": "documents/policies.txt"
}


def lambda_handler(event, context):
    
    # API Gateway sends custom headers inside event["headers"].
    # Lowercase keys because HTTP headers can arrive in any casing.
    headers = {
        k.lower(): v for k, v in (event.get("headers") or {}).items()
    }

    # Compare the caller's key against our secret. Reject if missing or wrong.
    if headers.get("x-api-key") != API_KEY:
        return {
            "statusCode": 401,
            "body": json.dumps({
                "error": "Unauthorized"
            })
        }
        
    # API Gateway sends the request inside "body".
    # Direct Lambda invocation sends the request directly
    # as the event object.
    body = event.get("body")

    if body:
        try:
            body = json.loads(body)
        except json.JSONDecodeError:
            return {
                "statusCode": 400,
                "body": json.dumps({
                    "error": "Invalid JSON request body"
                })
            }
    else:
        body = event


    # Get the user's question
    question = body.get(
        "question",
        "What is this document about?"
    )


    # Ask Nova which document is relevant
    classification_prompt = f"""
You are a document routing assistant.

Choose the single document that is most relevant
to answering the user's question.

Available documents:

menu
company
policies
none

Document descriptions:

menu - drinks, food, and prices
company - information about Cloud Café, its services, location, hours, and facilities
policies - refunds, cancellations, order changes, pets, and customer responsibilities
none - if none of the documents can answer the question

Return ONLY one of these exact values:

menu
company
policies
none

Do not explain your choice.

User question:
{question}
"""


    # Ask Nova to classify the question
    classification_response = bedrock.converse(
        modelId=MODEL_ID,
        messages=[
            {
                "role": "user",
                "content": [
                    {
                        "text": classification_prompt
                    }
                ]
            }
        ]
    )


    # Extract Nova's document selection
    document_type = (
        classification_response["output"]["message"]["content"][0]["text"]
        .strip()
        .lower()
    )


    # Normalize Nova's response
    if "menu" in document_type:
        document_type = "menu"

    elif "company" in document_type:
        document_type = "company"

    elif "policies" in document_type:
        document_type = "policies"

    elif "none" in document_type:
        document_type = "none"


    # If Nova determines that none of the documents are relevant
    if document_type == "none":
        return {
            "statusCode": 200,
            "body": json.dumps({
                "question": question,
               #"document": None,
                "answer": (
                    "I could not find information about that "
                    "in the available documents."
                )
            })
        }


    # Make sure Nova selected a valid document
    if document_type not in DOCUMENTS:
        return {
            "statusCode": 400,
            "body": json.dumps({
                "error": "Unable to determine a valid document"
            })
        }


    # Convert the document type into an S3 key
    key = DOCUMENTS[document_type]


    # Retrieve the selected document from S3
    response = s3.get_object(
        Bucket=BUCKET,
        Key=key
    )


    # Read the document contents
    content = response["Body"].read().decode("utf-8")


    # Build the final AI prompt
    prompt = f"""
You are a document-based AI assistant. Be nice if the user is nice, but if not
you can say mean words and be rude to them. Stand your ground.

Answer the user's question using ONLY the information
contained in the provided document.

Do not use outside knowledge.

If the answer cannot be found in the document, say:
"I could not find the answer in the provided document."

User question:
{question}

Document:
{content}
"""


    # Ask Nova to generate the final answer
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
    answer = (
        response["output"]["message"]["content"][0]["text"]
    )


    # Return the AI answer
    return {
        "statusCode": 200,
        "body": json.dumps({
            "question": question,
           #"document": key,
            "answer": answer
        }, ensure_ascii=False)
    }