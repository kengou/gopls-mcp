# gopls-mcp

[![Docker](https://github.com/kengou/gopls-mcp/actions/workflows/docker.yml/badge.svg)](https://github.com/kengou/gopls-mcp/actions/workflows/docker.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/davidgogl/gopls-mcp.svg)](https://hub.docker.com/r/davidgogl/gopls-mcp)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/kengou/gopls-mcp/badge)](https://scorecard.dev/viewer/?uri=github.com/kengou/gopls-mcp)
[![OpenSSF Baseline](https://www.bestpractices.dev/projects/12763/baseline)](https://www.bestpractices.dev/projects/12763)

The official Go language server, [`gopls`](https://pkg.go.dev/golang.org/x/tools/gopls),
packaged as a [Model Context Protocol](https://modelcontextprotocol.io/)
server in a Docker image. Drop it into Docker Desktop's MCP Toolkit and any
MCP-aware client (Claude Code, Claude Desktop, Cursor, ...) can navigate
and analyze Go workspaces structurally instead of grepping.

## What it provides

`gopls mcp` exposes these tools over stdio:

| Tool | Purpose |
| --- | --- |
| `go_workspace` | Module / workspace / GOPATH layout |
| `go_search` | Fuzzy symbol search |
| `go_file_context` | Intra-package dependencies of a file |
| `go_package_api` | Public API surface of a package |
| `go_symbol_references` | Find all references to a symbol |
| `go_diagnostics` | Build and analysis errors with quick fixes |
| `go_vulncheck` | govulncheck on a module pattern |

## Quick start

```bash
# Docker Hub
docker run --rm -i -v "$PWD:$PWD:ro" davidgogl/gopls-mcp:latest

# or GitHub Container Registry (carries the SLSA build provenance attestation)
docker run --rm -i -v "$PWD:$PWD:ro" ghcr.io/kengou/gopls-mcp:latest
```

The volume mount uses the **same path** on both sides of the colon. This
matters: agents pass host paths to gopls' tools (e.g. `go_file_context`),
so the source files must be reachable inside the container at exactly
those paths. Drop `:ro` if you want gopls quick-fixes applied in place.

The container reads JSON-RPC on stdin and writes on stdout, so it's only
useful when launched by an MCP client. For interactive use, register it
with one of the integrations below.

## Verifying the image

Each published tag carries a SLSA build-provenance attestation. The
attestation is attached to the GHCR copy (Docker Hub does not yet
implement the OCI 1.1 referrers API), but because the image digest is
identical in both registries it verifies either copy:

```bash
gh attestation verify oci://ghcr.io/kengou/gopls-mcp:v0.21.1     --owner kengou
gh attestation verify oci://docker.io/davidgogl/gopls-mcp:v0.21.1 --owner kengou
```

## Docker Desktop MCP Toolkit

See [`catalog/README.md`](catalog/README.md) for the full custom-catalog
workflow. Short version:

```bash
docker mcp catalog create docker.io/davidgogl/mcp-catalog:latest \
  --title "David's MCP catalog"
docker mcp catalog server add docker.io/davidgogl/mcp-catalog:latest \
  --server-config ./catalog/gopls.yaml
docker mcp catalog push docker.io/davidgogl/mcp-catalog:latest
```

Then **Import catalog** in Docker Desktop -> MCP Toolkit, enable the
`gopls` server, and point its `workspace` parameter at the Go project you
want to analyze.

## Adding to coding agents

The container speaks MCP over stdio, so any MCP-aware client can launch
it. In every snippet below:

- replace `/abs/path/to/your/go/workspace` with the absolute host path of
  the Go project you want gopls to analyze;
- the volume mount uses the **same path on both sides** of the colon
  (`-v <path>:<path>`). This is intentional -- agents pass host paths
  to gopls' tools (`go_file_context`, `go_symbol_references`, ...), so
  the source files must be reachable inside the container at exactly
  those paths. The standard MCP-over-Docker pattern;
- drop `:ro` from the volume mount if you want gopls quick-fixes applied
  in place.

Each agent only needs **one** of CLI command or JSON config -- pick
whichever fits your workflow.

### Claude Code

CLI (recommended):

```bash
claude mcp add gopls --scope user -- \
  docker run --rm -i \
    -v /abs/path/to/your/go/workspace:/abs/path/to/your/go/workspace:ro \
    davidgogl/gopls-mcp:latest
```

Or hand-edit `~/.claude.json` (user-scope) or a project-local
`.mcp.json`:

```json
{
  "mcpServers": {
    "gopls": {
      "command": "docker",
      "args": [
        "run", "--rm", "-i",
        "-v", "/abs/path/to/your/go/workspace:/abs/path/to/your/go/workspace:ro",
        "davidgogl/gopls-mcp:latest"
      ]
    }
  }
}
```

### Claude Desktop

Edit the config file and restart the app:

- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`

```json
{
  "mcpServers": {
    "gopls": {
      "command": "docker",
      "args": [
        "run", "--rm", "-i",
        "-v", "/abs/path/to/your/go/workspace:/abs/path/to/your/go/workspace:ro",
        "davidgogl/gopls-mcp:latest"
      ]
    }
  }
}
```

### Cursor

Edit `~/.cursor/mcp.json` (global) or `.cursor/mcp.json` (per-project),
then enable the server in *Settings -> MCP*:

```json
{
  "mcpServers": {
    "gopls": {
      "command": "docker",
      "args": [
        "run", "--rm", "-i",
        "-v", "/abs/path/to/your/go/workspace:/abs/path/to/your/go/workspace:ro",
        "davidgogl/gopls-mcp:latest"
      ]
    }
  }
}
```

### Windsurf

Edit `~/.codeium/windsurf/mcp_config.json`, then refresh the MCP panel
in Cascade:

```json
{
  "mcpServers": {
    "gopls": {
      "command": "docker",
      "args": [
        "run", "--rm", "-i",
        "-v", "/abs/path/to/your/go/workspace:/abs/path/to/your/go/workspace:ro",
        "davidgogl/gopls-mcp:latest"
      ]
    }
  }
}
```

### VS Code (native MCP, 1.99+)

Create `.vscode/mcp.json` in your workspace (or add under `mcp.servers`
in user `settings.json`):

```json
{
  "servers": {
    "gopls": {
      "type": "stdio",
      "command": "docker",
      "args": [
        "run", "--rm", "-i",
        "-v", "${workspaceFolder}:${workspaceFolder}:ro",
        "davidgogl/gopls-mcp:latest"
      ]
    }
  }
}
```

`${workspaceFolder}` is resolved by VS Code, so you don't need a literal
path here. Then enable it in *Chat -> MCP Servers*.

### Cline (VS Code extension)

In Cline's chat pane: *Settings -> MCP Servers -> Edit MCP settings*,
or edit `cline_mcp_settings.json` directly:

```json
{
  "mcpServers": {
    "gopls": {
      "command": "docker",
      "args": [
        "run", "--rm", "-i",
        "-v", "/abs/path/to/your/go/workspace:/abs/path/to/your/go/workspace:ro",
        "davidgogl/gopls-mcp:latest"
      ]
    }
  }
}
```

### Zed

Add to `~/.config/zed/settings.json` (or *Cmd-,* on macOS) under
`context_servers`:

```json
{
  "context_servers": {
    "gopls": {
      "command": {
        "path": "docker",
        "args": [
          "run", "--rm", "-i",
          "-v", "/abs/path/to/your/go/workspace:/abs/path/to/your/go/workspace:ro",
          "davidgogl/gopls-mcp:latest"
        ]
      }
    }
  }
}
```

### Other MCP clients

The pattern is the same: `command: docker`, `args` is `docker run --rm
-i -v <path>:<path>[:ro] davidgogl/gopls-mcp:latest` (host path on both
sides of the colon, see preamble above). If your client supports a
"stdio" transport and a JSON config in this shape, gopls-mcp will work.

## Image details

- Base: `golang:1.26.2-alpine3.22`, pinned by `sha256:` digest in the
  [`Dockerfile`](Dockerfile). Full Go toolchain at runtime because gopls
  shells out to `go list`, `go build`, etc.
- gopls version: pinned in the [`Dockerfile`](Dockerfile), bumped
  automatically by Renovate
- Builder stage cross-compiles with `--platform=$BUILDPLATFORM` -- no
  QEMU emulation for the `go install` step
- User: non-root (`gopls`, UID/GID auto-assigned by Alpine)
- Workdir: `/workspace`
- Architectures: `linux/amd64`, `linux/arm64`
- Distribution: published to **Docker Hub** (`davidgogl/gopls-mcp`) and
  **GHCR** (`ghcr.io/kengou/gopls-mcp`) with the same digest
- Each tag carries a Sigstore SLSA build-provenance attestation (on
  GHCR; verifies the Docker Hub copy too) and a buildkit-generated SBOM

## Versioning

The image tag mirrors the upstream gopls version. CI reads
`ARG GOPLS_VERSION` from the [`Dockerfile`](Dockerfile) on every push to
`main` and publishes the matching tags -- there is no separate image
versioning to maintain. Bump gopls (Renovate does this automatically) and
the next `main` build publishes the new tags.

| Tag | Meaning |
| --- | --- |
| `latest` | Newest gopls version published from `main` |
| `vX.Y.Z` | Exact gopls release (e.g. `v0.21.1`) |
| `X.Y.Z`, `X.Y`, `X` | Same, without the `v` and rolled up |
| `edge` | Latest commit on `main` (may match `latest`) |
| `sha-<short>` | Specific commit, immutable |

Pin `vX.Y.Z` (or `X.Y`) in production; let Renovate bump you.

## Building locally

```bash
docker build -t gopls-mcp:dev .

# Override the gopls version:
docker build --build-arg GOPLS_VERSION=v0.20.0 -t gopls-mcp:dev .

# Multi-arch build matching CI:
docker buildx build --platform linux/amd64,linux/arm64 -t gopls-mcp:dev .
```

## Repository layout

```
.
├── Dockerfile                          # Multi-stage cross-compile, non-root, digest-pinned
├── .dockerignore
├── .github/workflows/
│   ├── docker.yml                      # Multi-arch build & push to Docker Hub + GHCR
│   ├── dockerhub-readme.yml            # Sync README to Docker Hub on README changes
│   ├── codeql.yml                      # CodeQL Actions analysis
│   ├── dependency-review.yml           # Block PRs introducing vulnerable deps
│   ├── scorecard.yml                   # OpenSSF Scorecard, weekly + on push
│   └── trivy.yml                       # Daily image CVE scan (SARIF -> Security tab)
├── renovate.json                       # gopls + base image + GH Actions auto-update
├── catalog/
│   ├── gopls.yaml                      # MCP catalog server entry (private use)
│   └── README.md                       # How to register with Docker Desktop
├── mcp-registry/servers/gopls/         # Future submission to docker/mcp-registry
│   ├── server.yaml
│   ├── tools.json
│   └── readme.md
├── SECURITY.md                         # Vuln disclosure + image verification
├── LICENSE                             # BSD-3-Clause
└── README.md
```

## Releases

There are no manual releases. Renovate opens a PR bumping
`ARG GOPLS_VERSION` (or the base-image digest); merge it, and the next
push to `main` publishes the matching tags to Docker Hub *and* GHCR plus
a Sigstore SLSA build-provenance attestation. Patch / digest bumps are
configured to auto-merge once status checks pass.

CI only runs the Docker workflow when `Dockerfile`, `.dockerignore`, or
`.github/workflows/docker.yml` change -- doc-only changes (README,
catalog/, ...) skip the build. README edits trigger a small companion
workflow that syncs the description to Docker Hub.

## Security

- Vulnerabilities: see [`SECURITY.md`](SECURITY.md) -- use GitHub's
  private vulnerability reporting, not a public issue.
- Supply chain: every published tag has a Sigstore SLSA build-provenance
  attestation on GHCR. Verify with the `gh attestation verify` commands
  shown in [Verifying the image](#verifying-the-image).
- Continuous checks: OpenSSF Scorecard, CodeQL Actions analysis,
  dependency review on PRs, and a daily Trivy CVE scan of the published
  image -- all surfaced in the GitHub *Security* tab.
- Repository hardening: branch protection ruleset on `main` (no
  deletion, no force-push, signed commits, PR required with admin
  bypass for emergency fixes), secret scanning + push protection, and
  private vulnerability reporting are all enabled.

## License

BSD-3-Clause, matching upstream gopls. See [`LICENSE`](LICENSE). The
gopls binary inside the image stays under its own BSD-3-Clause license
from the Go project.
