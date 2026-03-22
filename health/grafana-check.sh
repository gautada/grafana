#!/bin/sh
# ╭──────────────────────────────────────────────────────────╮
# │ Grafana health check                                     │
# ╰──────────────────────────────────────────────────────────╯

PORT="${GRAFANA_PORT:-3000}"
HEALTH_URL="http://127.0.0.1:${PORT}/api/health"

if ! curl -fsSL "${HEALTH_URL}" >/dev/null 2>&1; then
  printf 'Grafana is not responding on %s\n' "${PORT}" >&2
  exit 1
fi

echo "Grafana OK"
