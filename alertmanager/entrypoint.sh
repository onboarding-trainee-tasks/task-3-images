#!/bin/sh

set -eu

printf '%s' "$SMTP_PASSWORD" \
  > /etc/alertmanager/secrets/smtp_password

chmod 600 \
  /etc/alertmanager/secrets/smtp_password

exec /bin/alertmanager \
  --config.file=/etc/alertmanager/alertmanager.yml \
  --storage.path=/alertmanager \
  --web.listen-address=0.0.0.0:9093