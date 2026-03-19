#!/bin/sh
# ╭――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――╮
# │ VERSION - GRAFANA VERSION REPORT                                         │
# ╰――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――╯
# This script returns the Grafana version packaged in the container.

VERSION=$(/usr/sbin/grafana-server -v | awk '{print $2}' | tr -d '[:space:]')

if [ -z "$VERSION" ]; then
    printf "unknown\n"
    exit 1
fi

printf "%s\n" "$VERSION"
