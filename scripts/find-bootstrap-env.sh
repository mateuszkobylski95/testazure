#!/usr/bin/env bash
set -euo pipefail

for candidate in /opt/*/.bootstrap.env; do
  if [ -f "$candidate" ]; then
    echo "$candidate"
    exit 0
  fi
done
