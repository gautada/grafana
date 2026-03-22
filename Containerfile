# syntax=docker/dockerfile:1.7

ARG BASE_IMAGE=docker.io/gautada/debian:latest
ARG GRAFANA_VERSION=11.2.0
ARG TARGETARCH=amd64

# ══════════════════════════════════════════════════════════════
# Stage 1: Build Grafana from source
# ══════════════════════════════════════════════════════════════
FROM ${BASE_IMAGE} AS builder

ARG GRAFANA_VERSION
ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive
ENV GOOS=linux
ENV GOARCH=${TARGETARCH}
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0

# hadolint ignore=DL3008,DL4006
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    git \
    gnupg \
    pkg-config \
    python3 \
 && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
 && apt-get install -y --no-install-recommends \
    nodejs \
    golang \
 && corepack enable \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN git config --global advice.detachedHead false \
 && git clone --depth 1 --branch "v${GRAFANA_VERSION}" https://github.com/grafana/grafana.git .

WORKDIR /build
RUN corepack prepare yarn@1.22.22 --activate \
 && yarn config set network-timeout 300000

ENV NODE_ENV=production
# hadolint ignore=DL3062
RUN yarn install --frozen-lockfile \
 && yarn build \
 && make build-go

# ══════════════════════════════════════════════════════════════
# Stage 2: Runtime container
# ══════════════════════════════════════════════════════════════
FROM ${BASE_IMAGE} AS container

ARG IMAGE_NAME=grafana
ARG TARGETARCH

LABEL org.opencontainers.image.title="${IMAGE_NAME}"
LABEL org.opencontainers.image.description="Grafana dashboard server built from source"
LABEL org.opencontainers.image.source="https://github.com/gautada/grafana"
LABEL org.opencontainers.image.license="Apache-2.0"

ENV DEBIAN_FRONTEND=noninteractive

# hadolint ignore=DL3008
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    libfontconfig1 \
    libfreetype6 \
    libx11-6 \
    libxext6 \
    libxrender1 \
    libxtst6 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Application layout
RUN mkdir -p /usr/share/grafana \
           /etc/grafana/provisioning \
           /var/lib/grafana \
           /var/log/grafana

# Grafana binaries and assets
COPY --from=builder /build/bin/linux-${TARGETARCH}/grafana-server /usr/sbin/grafana-server
COPY --from=builder /build/bin/linux-${TARGETARCH}/grafana-cli /usr/bin/grafana-cli
COPY --from=builder /build/conf /usr/share/grafana/conf
COPY --from=builder /build/public /usr/share/grafana/public
COPY --from=builder /build/tools /usr/share/grafana/tools
COPY --from=builder /build/plugins-bundled /usr/share/grafana/plugins-bundled

# Configuration
COPY config.ini /etc/grafana/grafana.ini
RUN chmod 0644 /etc/grafana/grafana.ini

# Runtime user
ARG USER=grafana
RUN adduser --system --home /home/$USER --shell /bin/bash $USER \
 && chown -R $USER:$USER /home/$USER /var/lib/grafana /var/log/grafana

ENV GRAFANA_PORT=3000

# s6 service + health checks
RUN mkdir -p /etc/services.d/grafana /etc/container/health.d
COPY services/grafana/run /etc/services.d/grafana/run
COPY health/grafana-check.sh /etc/container/health.d/grafana-running
RUN chmod +x /etc/services.d/grafana/run /etc/container/health.d/grafana-running

# Version helper
COPY scripts/container-version.sh /usr/bin/container-version
RUN chmod +x /usr/bin/container-version

EXPOSE 3000/tcp
WORKDIR /usr/share/grafana

VOLUME ["/var/lib/grafana", "/var/log/grafana"]

