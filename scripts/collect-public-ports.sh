#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${1:-}"

if [ -z "$REPO_DIR" ]; then
  BOOTSTRAP_FILE="$(find /opt -maxdepth 2 -name ".bootstrap.env" | head -n 1)"

  if [ -z "$BOOTSTRAP_FILE" ]; then
    echo "[]"
    exit 0
  fi

  REPO_DIR="$(dirname "$BOOTSTRAP_FILE")"
fi

SERVICES_DIR="$REPO_DIR/services"

if [ ! -d "$SERVICES_DIR" ]; then
  echo "[]"
  exit 0
fi

PORTS=()

for file in "$SERVICES_DIR"/*.yml; do
  [ -f "$file" ] || continue

  HAS_DOMAIN="$(grep '^has_domain:' "$file" | awk '{print $2}')"

  if [ "$HAS_DOMAIN" != "false" ]; then
    continue
  fi

  PORT="$(grep '^public_port:' "$file" | awk '{print $2}')"

  if [ -z "$PORT" ] || [ "$PORT" = "null" ]; then
    continue
  fi

  PORTS+=("$PORT")
done

if [ "${#PORTS[@]}" -eq 0 ]; then
  echo "[]"
  exit 0
fi

UNIQUE_SORTED="$(printf '%s\n' "${PORTS[@]}" | sort -nu | paste -sd, -)"

echo "[${UNIQUE_SORTED}]"
