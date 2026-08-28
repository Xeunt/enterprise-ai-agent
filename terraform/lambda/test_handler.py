import boto3
from handler import lambda_handler


def test_lambda_handler():
    event = {
    "question": "What is Terraform?",
    "key": "documents/terraform.txt"
    }

    response = lambda_handler(event, None)

    assert response["statusCode"] == 200

    body = response["body"]

    assert "documents/terraform.txt" in body
    assert "Terraform is an Infrastructure as Code tool" in body
    
    test_lambda_handler()
    print("Test passed!")

