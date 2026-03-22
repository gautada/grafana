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
# RUN corepack prepare yarn@1.22.22 --activate \
#  && yarn config set network-timeout 300000

ENV NODE_ENV=production
# hadolint ignore=DL3062
RUN yarn install --frozen-lockfile
RUN yarn build
#  && go run build.go build
RUN make build-go
ENTRYPOINT ["tail", "-f", "/dev/null"]










# # syntax=docker/dockerfile:1.7
#
# ARG BASE_IMAGE=docker.io/gautada/debian:latest
# FROM ${BASE_IMAGE} AS container
#
# ARG IMAGE_NAME=grafana
#
# # ╭――――――――――――――――――――╮
# # │ METADATA           │
# # ╰――――――――――――――――――――╯
# LABEL org.opencontainers.image.title="${IMAGE_NAME}"
# LABEL org.opencontainers.image.description="A Grafana dashboard server container."
# LABEL org.opencontainers.image.source="https://github.com/gautada/grafana"
# LABEL org.opencontainers.image.license="Apache-2.0"
#
# # ╭――――――――――――――――――――╮
# # │ PACKAGES           │
# # ╰――――――――――――――――――――╯
# # Install Grafana from the official APT repository.
# RUN apt-get update \
#  && apt-get install --yes --no-install-recommends \
#     ca-certificates  curl gnupg \
#  && mkdir -p /etc/apt/keyrings \
#  && curl -fsSL https://apt.grafana.com/gpg.key | gpg --dearmor | tee /etc/apt/keyrings/grafana.gpg > /dev/null 
#  # && echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | tee /etc/apt/sources.list.d/grafana.list \
#  # && apt-get update \
#  # && apt-get install --yes --no-install-recommends grafana \
# RUN apt-get clean \
#  && rm -rf /var/lib/apt/lists/*
#
# # # ╭――――――――――――――――――――╮
# # # │ USER               │
# # # ╰――――――――――――――――――――╯
# # # Use the official grafana user created by the package.
# # ARG USER=grafana
# # RUN /usr/sbin/usermod -d /home/$USER -m $USER \
# #  && /bin/echo "$USER:$USER" | /usr/sbin/chpasswd \
# #  && chown -R $USER:$USER /etc/grafana /var/lib/grafana /var/log/grafana
# # ╭──────────────────────────────────────────────────────────╮
# # │ User                                                     │
# # ╰──────────────────────────────────────────────────────────╯
# ARG USER=watcher
# RUN /usr/sbin/usermod -l $USER debian \
#  && /usr/sbin/usermod -d /home/$USER -m $USER \
#  && /usr/sbin/groupmod -n $USER debian \
#  && /bin/passwd -d $USER \
#  && rm -rf /home/debian 
#
# # ╭――――――――――――――――――――╮
# # │ CONFIGURATION      │
# # ╰――――――――――――――――――――╯
# COPY config.ini /etc/grafana/grafana.ini
# RUN chown $USER:$USER /etc/grafana/grafana.ini
#
# # ╭――――――――――――――――――――╮
# # │ VERSION            │
# # ╰――――――――――――――――――――╯
# COPY scripts/container-version.sh /usr/bin/container-version
# RUN chmod +x /usr/bin/container-version
#
# # ╭――――――――――――――――――――╮
# # │ HEALTH             │
# # ╰――――――――――――――――――――╯
# COPY health/grafana-check.sh /etc/container/health.d/grafana-running
# RUN chmod +x /etc/container/health.d/grafana-running
#
# # ╭――――――――――――――――――――╮
# # │ ENTRYPOINT         │
# # ╰――――――――――――――――――――╯
# COPY services/grafana/run /etc/services.d/grafana/run
# RUN chmod +x /etc/services.d/grafana/run
#
# EXPOSE 3000/tcp
# WORKDIR /home/grafana
