import json
import os
from urllib.request import Request, urlopen

import boto3


def lambda_handler(event, context):
    if event.get("source") != "aws.cloudwatch" or "alarmData" not in event:
        raise ValueError("Expected a CloudWatch alarm action event")

    alarm = event["alarmData"]
    state = alarm["state"]
    name = alarm["alarmName"]
    value = state["value"]
    reason = state.get("reason", "No reason provided")
    icon = ":white_check_mark:" if value == "OK" else ":rotating_light:"
    color = "good" if value == "OK" else "danger"
    message = f"{icon} *{name}* is *{value}*\n{reason}"
    # Slack's attachment color draws the left border; fallback covers clients
    # that cannot render the formatted attachment.
    payload = {
        "attachments": [
            {
                "color": color,
                "fallback": f"{name} is {value}: {reason}",
                "text": message,
                "mrkdwn_in": ["text"],
            }
        ]
    }

    # Fetch the current URL at invocation time so rotations need no deployment.
    secret = boto3.client("secretsmanager").get_secret_value(
        SecretId=os.environ["SLACK_WEBHOOK_SECRET_ARN"]
    )
    webhook_url = secret["SecretString"].strip()
    if not webhook_url.startswith("https://hooks.slack.com/services/"):
        raise ValueError("Slack webhook secret is not an Incoming Webhook URL")

    request = Request(
        webhook_url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urlopen(request, timeout=5) as response:
        # Raise on rejection so Lambda's asynchronous invocation can retry.
        if response.read().strip() != b"ok":
            raise RuntimeError("Slack did not accept the notification")
