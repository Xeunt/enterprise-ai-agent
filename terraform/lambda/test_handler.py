from handler import lambda_handler


def test_lambda_handler():
    event = {
        "question": "What is Terraform?"
    }

    response = lambda_handler(event, None)

    assert response["statusCode"] == 200

    body = response["body"]

    assert "What is Terraform?" in body