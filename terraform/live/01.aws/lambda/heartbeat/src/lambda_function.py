import os
import hmac
import hashlib
import boto3


def verify(token):
    actual = hashlib.sha256(token.encode()).hexdigest()
    expected = os.environ["HEARTBEAT_TOKEN_SHA256"]
    return hmac.compare_digest(actual, expected)


def put_heartbeat_metric():
    client = boto3.client("cloudwatch")
    client.put_metric_data(
        Namespace=os.environ["HEARTBEAT_NAMESPACE"],
        MetricData=[{"MetricName": "Heartbeat", "Value": 1, "Unit": "Count"}],
    )


def lambda_handler(event, context):
    if "Records" in event:
        expected_topic = os.environ["HEARTBEAT_TOPIC_ARN"]
        if any(
            record.get("EventSource") == "aws:sns"
            and record.get("Sns", {}).get("TopicArn") == expected_topic
            and record.get("Sns", {}).get("Message") == "Watchdog"
            for record in event["Records"]
        ):
            put_heartbeat_metric()
        return {"statusCode": 204}

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

    put_heartbeat_metric()

    return {"statusCode": 204}
