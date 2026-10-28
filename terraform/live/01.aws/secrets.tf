# Only the secret container is managed here. Add the webhook URL outside
# OpenTofu so its plaintext never enters the state file.
resource "aws_secretsmanager_secret" "slack_webhook" {
  name        = "homelab/slack-notifications-webhook"
  description = "Slack Incoming Webhook for homelab CloudWatch alarms"
}
