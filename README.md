# grafana

[Grafana](https://grafana.com) — Dashboard anything. Observe everything.
Query, visualize, alert on, and understand your data no matter where it’s stored.
With Grafana you can create, explore and share all of your data through beautiful,
flexible dashboards.

## Container

### Versions

- Updated to use the official Grafana APT repository for stable releases.
- Built on the \`gautada/debian\` base image.

### Usage

\`\`\`sh
podman run -p 3000:3000 gautada/grafana:latest
\`\`\`

## Configuration

### Anonymous Auth

The default for this container is to not have authentication.
The \`/etc/grafana/grafana.ini\` file provides this default configuration.

\`\`\`ini
[auth.anonymous]
enabled = true
org_name = Main Org.
org_role = Admin
hide_version = false
\`\`\`

### Paths

- Configuration file: \`/etc/grafana/grafana.ini\`
- Data directory: \`/var/lib/grafana\`
- Log directory: \`/var/log/grafana\`
- Provisioning directory: \`/etc/grafana/provisioning\`
