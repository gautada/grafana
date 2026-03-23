#!/bin/sh
# ╭──────────────────────────────────────────────────────────╮
# │ Grafana version reporter                                 │
# ╰──────────────────────────────────────────────────────────╯

VERSION=$(/usr/bin/grafana version 2>/dev/null | awk '{print $2}' | tr -d '\n')

if [ -z "${VERSION}" ]; then
  echo "unknown"
  exit 1
fi

echo "${VERSION}"
