import os
import boto3


def put_heartbeat_metric():
    client = boto3.client("cloudwatch")
    client.put_metric_data(
        Namespace=os.environ["HEARTBEAT_NAMESPACE"],
        MetricData=[{"MetricName": "Heartbeat", "Value": 1, "Unit": "Count"}],
    )


def lambda_handler(event, context):
    expected_topic = os.environ["HEARTBEAT_TOPIC_ARN"]
    if any(
        record.get("EventSource") == "aws:sns"
        and record.get("Sns", {}).get("TopicArn") == expected_topic
        and record.get("Sns", {}).get("Message") == "Watchdog"
        for record in event.get("Records", [])
    ):
        put_heartbeat_metric()

    return {"statusCode": 204}
