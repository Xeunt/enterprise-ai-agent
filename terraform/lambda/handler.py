import json


def lambda_handler(event, context):

    question = event.get(
        "question",
        "Hello"
    )

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Agent received your question",
            "question": question
        })
    }