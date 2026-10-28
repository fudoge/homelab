# Slack alarm notifications

After applying this stack, create a Slack Incoming Webhook for the desired channel
and add its URL as the value of the `homelab/slack-notifications-webhook` Secrets
Manager secret. Keep the URL out of OpenTofu variables and state.

The `homelab-heartbeat-slack-notify` Lambda accepts CloudWatch alarm action
events. The `homelab-heartbeat-missing` alarm invokes it when the heartbeat
stops and when the metric resumes. The alarm checks 3 one-minute periods and treats missing
data as breaching. Its Lambda resource permission is scoped to this alarm.
