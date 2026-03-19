# syntax=docker/dockerfile:1.7

ARG BASE_IMAGE=docker.io/gautada/debian:latest
FROM ${BASE_IMAGE} AS container

ARG IMAGE_NAME=grafana

# ╭――――――――――――――――――――╮
# │ METADATA           │
# ╰――――――――――――――――――――╯
LABEL org.opencontainers.image.title="${IMAGE_NAME}"
LABEL org.opencontainers.image.description="A Grafana dashboard server container."
LABEL org.opencontainers.image.source="https://github.com/gautada/grafana"
LABEL org.opencontainers.image.license="Apache-2.0"

# ╭――――――――――――――――――――╮
# │ PACKAGES           │
# ╰――――――――――――――――――――╯
# Install Grafana from the official APT repository.
RUN apt-get update \
 && apt-get install --yes --no-install-recommends \
    gnupg2 \
    software-properties-common \
 && curl -fsSL https://apt.grafana.com/gpg.key | gpg --dearmor | tee /etc/apt/keyrings/grafana.gpg > /dev/null \
 && echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | tee /etc/apt/sources.list.d/grafana.list \
 && apt-get update \
 && apt-get install --yes --no-install-recommends grafana \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# ╭――――――――――――――――――――╮
# │ USER               │
# ╰――――――――――――――――――――╯
# Use the official grafana user created by the package.
ARG USER=grafana
RUN /usr/sbin/usermod -d /home/$USER -m $USER \
 && /bin/echo "$USER:$USER" | /usr/sbin/chpasswd \
 && chown -R $USER:$USER /etc/grafana /var/lib/grafana /var/log/grafana

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
WORKDIR /home/grafana
