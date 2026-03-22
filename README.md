# gautada/grafana

This repository packages the upstream [Grafana](https://grafana.com) OSS server
as a container built entirely from source. The image tracks tagged Grafana
releases, compiles the frontend (Yarn/Webpack) and backend (Go) in a dedicated
builder stage, then copies the compiled artifacts into the standard
`gautada/debian` runtime with our health checks and s6 launch script.

## Features

- ✅ Built from Grafana source (no distro packages)
- ✅ Multi-architecture (`amd64`, `arm64`) via Go cross-compilation
- ✅ s6-supervised service with `/etc/services.d/grafana`
- ✅ Health probe (`/etc/container/health.d/grafana-running`)
- ✅ Version reporter (`/usr/bin/container-version`)
- ✅ Anonymous auth enabled by default (overridable via mounted `config.ini`)

## Build

```bash
# Build the latest release (default ARG is 11.2.0)
podman build -t gautada/grafana .

# Build a specific Grafana tag
podman build \
  --build-arg GRAFANA_VERSION=11.1.4 \
  -t gautada/grafana:11.1.4 .
```

### Build arguments

| Argument            | Default                     | Description                                |
| ------------------- | --------------------------- | ------------------------------------------ |
| `BASE_IMAGE`        | `docker.io/gautada/debian`  | Runtime + builder base image               |
| `GRAFANA_VERSION`   | `11.2.0`                    | Upstream Grafana tag to clone and build    |
| `TARGETARCH`        | auto (Docker build arg)     | Architecture (`amd64`, `arm64`, …)         |

## Run

```bash
podman run -d \
  --name grafana \
  -p 3000:3000 \
  -v grafana-data:/var/lib/grafana \
  gautada/grafana:latest
```

### Volumes

- `/var/lib/grafana` – persistent data, plugins, dashboards
- `/var/log/grafana` – optional log volume (default logs via stdout)

### Ports

- `3000/tcp` – Grafana HTTP API/UI (`GRAFANA_PORT` can override)

## Configuration

- Main config: `/etc/grafana/grafana.ini` (default enables anonymous admin)
- Provisioning: `/etc/grafana/provisioning` (mount your datasources, dashboards)
- Plugins: `/var/lib/grafana/plugins`

To override the default config, bind mount or use a ConfigMap:

```bash
podman run -d \
  -p 3000:3000 \
  -v ./grafana.ini:/etc/grafana/grafana.ini:ro \
  gautada/grafana
```

## Health & Monitoring

- `container-test` runs `health/grafana-check.sh`, which queries `/api/health` on
  `http://127.0.0.1:${GRAFANA_PORT:-3000}` and fails the container if Grafana
  stops responding.
- `/usr/bin/container-version` reports the Grafana version baked into the image.

## Development notes

- The builder stage installs Node 20 LTS (via NodeSource), Yarn (via Corepack),
  and Go, then runs `yarn build && go run build.go build` just like the upstream
  release pipeline.
- The runtime stage only contains the compiled binaries/assets plus the Debian
  libraries Grafana needs at runtime (fontconfig/X11 libs for rendering).
- s6 launches Grafana under the dedicated `grafana` user and wires up the
  expected paths (`/var/lib/grafana`, `/var/log/grafana`, etc.).

## License

Grafana OSS is licensed under AGPLv3. This container’s additional code (scripts,
health checks) is MIT, matching the rest of the gautada org.
