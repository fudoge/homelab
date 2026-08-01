#!/usr/bin/env bash

[ "$EUID" -ne 0 ] && echo "root account required" && exit 1

apt update

apt upgrade -y

apt install jq -y

cat <<EOF >/root/update_cert.sh
#!/bin/bash
NAME="$(tailscale status --json | jq '.Self.DNSName | .[:-1]' -r)"
tailscale cert "${NAME}"
pvenode cert set "${NAME}.crt" "${NAME}.key" --force --restart
EOF

chmod +x /root/update_cert.sh

CRON_COMMENT="# Tailscale cert"
CRON_JOB="0 */12 * * * /root/update_cert.sh"

if ! crontab -l 2>/dev/null | grep -Fqx "$CRON_COMMENT"; then
    {
        crontab -l 2>/dev/null || true
        echo "$CRON_COMMENT"
        echo "$CRON_JOB"
    } | crontab -
fi

tailscale serve --bg https+insecure://localhost:8006
