# Watchdog heartbeat

`alertmanager-config-watchdog.yaml` sends the always-firing Watchdog alert to
`https://heartbeat.chaewoon.work/api/heartbeat` every minute. The AWS Lambda
expects the original token as an `Authorization: Bearer` credential. Terraform
stores only its SHA-256 hash, so that hash cannot be used as the token.

Before deploying the AlertmanagerConfig, fill in `stringData.token` in
`secret-heartbeat-token.yaml` with the original token. From the repository root,
encrypt it with:

```bash
sops --encrypt --in-place k8s/infrastructure/observabilities/kube-prometheus-stack/alertmanager/secret-heartbeat-token.yaml
```

Then add the file to this directory's `kustomization.yaml`. Do not commit the
plaintext token. The repository's `.sops.yaml` encrypts Kubernetes `data` and
`stringData` fields.

The Lambda publishes the `homelab/heartbeat` CloudWatch metric, but the
Terraform configuration does not yet create an alarm for missing datapoints.
Until that alarm and its notification action exist, a stopped heartbeat will
not notify anyone.
