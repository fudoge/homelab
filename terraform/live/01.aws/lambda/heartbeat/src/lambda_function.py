import os
import hmac
import hashlib
import boto3


def verify(token):
    actual = hashlib.sha256(token.encode()).hexdigest()
    expected = os.environ["HEARTBEAT_TOKEN_SHA256"]
    return hmac.compare_digest(actual, expected)


def lambda_handler(event, context):
    # auth
    headers = {k.lower(): v for k, v in (event.get("headers") or {}).items()}
    scheme, separator, token = headers.get("authorization", "").partition(" ")
    if (
        scheme.lower() != "bearer"
        or not separator
        or not token
        or any(char.isspace() for char in token)
        or not verify(token)
    ):
        return {"statusCode": 401, "body": "Unauthorized"}

    # put metric data
    namespace = os.environ["HEARTBEAT_NAMESPACE"]
    client = boto3.client("cloudwatch")
    response = client.put_metric_data(
        Namespace=namespace,
        MetricData=[{"MetricName": "Heartbeat", "Value": 1, "Unit": "Count"}],
    )

    return {"statusCode": 204}
