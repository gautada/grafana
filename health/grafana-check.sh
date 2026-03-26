#!/bin/sh
# ╭――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――╮
# │ GRAFANA - HEALTH CHECK SCRIPT                                            │
# ╰――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――╯
# Verifies that Grafana is responding on its configured port.

PORT="${GRAFANA_PORT:-3000}"
HEALTH_ENDPOINT="http://localhost:${PORT}/api/health"

if ! curl -fsSL "${HEALTH_ENDPOINT}" > /dev/null 2>&1; then
    printf "Grafana is not responding on port %s\n" "${PORT}" >&2
    exit 1
fi

printf "Grafana is healthy\n"
