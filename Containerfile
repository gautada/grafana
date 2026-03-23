# syntax=docker/dockerfile:1.7

ARG BASE_IMAGE=docker.io/gautada/debian:latest
ARG GRAFANA_VERSION=11.2.0
ARG TARGETARCH=amd64

# ══════════════════════════════════════════════════════════════
# Stage 1: Build Grafana from source
# ══════════════════════════════════════════════════════════════
# FROM ${BASE_IMAGE} AS builder
FROM docker.io/library/golang:1.24-trixie AS builder

ARG GRAFANA_VERSION
ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive
ENV GOOS=linux
ENV GOARCH=${TARGETARCH}
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0
ENV NODE_OPTIONS=--max-old-space-size=6144

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
 && go mod edit -replace=github.com/grafana/pyroscope-go/godeltaprof=github.com/grafana/pyroscope-go/godeltaprof@v0.1.9 \
 && go mod tidy \
 && go mod download \
 && go list -m all | grep godeltaprof
#  && yarn config set network-timeout 300000

ENV NODE_ENV=production
# hadolint ignore=DL3062
RUN yarn install --frozen-lockfile \
 && yarn build \
 && sh -ec 'ulimit -n; ulimit -n 65536; ulimit -n; make build-go' \
 && yarn cache clean
# ENTRYPOINT ["tail", "-f", "/dev/null"]


FROM ${BASE_IMAGE} AS container

ARG TARGETARCH 

# ╭――――――――――――――――――――╮
# │ METADATA           │
# ╰――――――――――――――――――――╯
LABEL org.opencontainers.image.title="grafana"
LABEL org.opencontainers.image.description="A Grafana dashboard server container."
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
COPY --from=builder /build/bin/linux-${TARGETARCH}/grafana /usr/bin/grafana
COPY --from=builder /build/bin/linux-${TARGETARCH}/grafana-cli /usr/bin/grafana-cli
RUN ln -sf /usr/bin/grafana /usr/sbin/grafana-server
COPY --from=builder /build/conf /usr/share/grafana/conf
COPY --from=builder /build/public /usr/share/grafana/public
COPY --from=builder /build/tools /usr/share/grafana/tools
COPY --from=builder /build/plugins-bundled /usr/share/grafana/plugins-bundled

# ╭──────────────────────────────────────────────────────────╮
# │ User                                                     │
# ╰──────────────────────────────────────────────────────────╯
ARG USER=dashboard
RUN /usr/sbin/usermod -l $USER debian \
 && /usr/sbin/usermod -d /home/$USER -m $USER \
 && /usr/sbin/groupmod -n $USER debian \
 && /bin/passwd -d $USER \
 && rm -rf /home/debian 

# ╭――――――――――――――――――――╮
# │ CONFIGURATION      │
# ╰――――――――――――――――――――╯
COPY config.ini /etc/grafana/grafana.ini
RUN chown $USER:$USER /etc/grafana/grafana.ini

# ╭――――――――――――――――――――╮
# │ VERSION            │
# ╰――――――――――――――――――――╯
COPY scripts/container-version.sh /usr/bin/container-version
RUN chmod +x /usr/bin/container-version

# ╭――――――――――――――――――――╮
# │ HEALTH             │
# ╰――――――――――――――――――――╯
COPY health/grafana-check.sh /etc/container/health.d/grafana-running
RUN chmod +x /etc/container/health.d/grafana-running

# ╭――――――――――――――――――――╮
# │ ENTRYPOINT         │
# ╰――――――――――――――――――――╯
COPY services/grafana/run /etc/services.d/grafana/run
RUN chmod +x /etc/services.d/grafana/run

EXPOSE 3000/tcp
WORKDIR /
