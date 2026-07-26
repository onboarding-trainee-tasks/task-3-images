#!/bin/sh

set -eu

if [ -z "${ECS_CONTAINER_METADATA_URI_V4:-}" ]; then
  echo "ECS_CONTAINER_METADATA_URI_V4 is not available" >&2
  exit 1
fi

metadata="$(
  wget -qO- \
    "${ECS_CONTAINER_METADATA_URI_V4}/task"
)"

availability_zone="$(
  printf '%s' "$metadata" |
    tr -d '\n' |
    sed -n \
      's/.*"AvailabilityZone"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p'
)"

if [ -z "$availability_zone" ]; then
  echo "Could not determine task Availability Zone" >&2
  exit 1
fi

case "$availability_zone" in
  "$PROMETHEUS_AZ_1")
    storage_path="$PROMETHEUS_STORAGE_PATH_1"
    ;;

  "$PROMETHEUS_AZ_2")
    storage_path="$PROMETHEUS_STORAGE_PATH_2"
    ;;

  *)
    echo "Unsupported Availability Zone: $availability_zone" >&2
    exit 1
    ;;
esac

if [ ! -d "$storage_path" ]; then
  echo "Prometheus storage path does not exist: $storage_path" >&2
  exit 1
fi

if [ ! -w "$storage_path" ]; then
  echo "Prometheus storage path is not writable: $storage_path" >&2
  exit 1
fi

echo "Prometheus storage partition selected:"
echo "Availability Zone: $availability_zone"
echo "Storage path: $storage_path"

exec /bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path="$storage_path" \
  --storage.tsdb.retention.time="${PROMETHEUS_RETENTION_TIME:-15d}" \
  --storage.tsdb.wal-compression \
  --web.listen-address=0.0.0.0:9090