# Watchdog heartbeat

`alertmanager-config-watchdog.yaml` publishes the always-firing Watchdog
alert to the `homelab-heartbeat` SNS topic every minute. Alertmanager uses a
projected token from the chart's existing
`kube-prometheus-stack-alertmanager` service account to assume the
`homelab-alertmanager` IAM role. The SNS-triggered Lambda records the
`homelab/heartbeat` CloudWatch metric.

The HTTP API and encrypted `heartbeat-token` Secret remain available during
the switch. The Lambda still accepts the Bearer token on the HTTP path.

`homelab-heartbeat-missing` CloudWatch alarm treats missing datapoints as
breaching and invokes `homelab-heartbeat-slack-notify` on ALARM and OK transitions.
