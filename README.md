# gopls-mcp

[![Docker](https://github.com/kengou/gopls-mcp/actions/workflows/docker.yml/badge.svg)](https://github.com/kengou/gopls-mcp/actions/workflows/docker.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/davidgogl/gopls-mcp.svg)](https://hub.docker.com/r/davidgogl/gopls-mcp)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/kengou/gopls-mcp/badge)](https://scorecard.dev/viewer/?uri=github.com/kengou/gopls-mcp)

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
docker run --rm -i -v "$PWD:/workspace:ro" davidgogl/gopls-mcp:latest

# or GitHub Container Registry (carries the SLSA build provenance attestation)
docker run --rm -i -v "$PWD:/workspace:ro" ghcr.io/kengou/gopls-mcp:latest
```

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

## Claude Code / Claude Desktop

Add to your MCP client config (`~/.claude/claude_desktop_config.json` for
Desktop; equivalent for Claude Code):

```json
{
  "mcpServers": {
    "gopls": {
      "command": "docker",
      "args": [
        "run", "--rm", "-i",
        "-v", "/abs/path/to/your/go/workspace:/workspace:ro",
        "davidgogl/gopls-mcp:latest"
      ]
    }
  }
}
```

Replace `/abs/path/to/your/go/workspace` with the path on your machine.
Drop `:ro` if you want gopls quick-fixes to be applied directly.

## Image details

- Base: `golang:1.26.2-alpine3.22` (full Go toolchain at runtime; gopls
  shells out to `go list`, `go build`, etc.)
- gopls version: pinned in [`Dockerfile`](Dockerfile),
  bumped automatically by Renovate
- User: non-root (`gopls`, UID/GID auto-assigned by Alpine)
- Workdir: `/workspace`
- Architectures: `linux/amd64`, `linux/arm64`
- Build provenance + SBOM attached to every published tag

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
docker build --build-arg GOPLS_VERSION=v0.21.1 -t gopls-mcp:dev .
```

## Repository layout

```
.
├── Dockerfile                  # Multi-stage build, non-root, pinned versions
├── .dockerignore
├── .github/workflows/docker.yml  # Multi-arch build & push to Docker Hub + GHCR
├── renovate.json               # gopls + Go base image auto-update
├── catalog/
│   ├── gopls.yaml              # MCP catalog server entry (private use)
│   └── README.md               # How to register with Docker Desktop
├── mcp-registry/servers/gopls/   # Submission to docker/mcp-registry
│   ├── server.yaml
│   ├── tools.json
│   └── readme.md
└── README.md
```

## Releases

There are no manual releases. Merge a Renovate PR (or hand-edit
`ARG GOPLS_VERSION` in the Dockerfile), push to `main`, and CI publishes
the matching tags to Docker Hub plus a Sigstore-backed build provenance
attestation.

## CI secrets

The `docker.yml` workflow needs two repository secrets:

- `DOCKERHUB_USERNAME` -- your Docker Hub user
- `DOCKERHUB_TOKEN` -- a Docker Hub
  [access token](https://hub.docker.com/settings/security) with
  `Read, Write` scope on the `davidgogl/gopls-mcp` repo

GHCR uses the built-in `GITHUB_TOKEN`; no extra secret needed. The first
push creates the package as **private** -- visit
<https://github.com/users/kengou/packages/container/gopls-mcp/settings>
once and set visibility to public so the SLSA verification command in
the README works without auth.

## Security

- Vulnerabilities: see [`SECURITY.md`](SECURITY.md) -- use GitHub's
  private vulnerability reporting, not a public issue.
- Supply chain: every published tag has a Sigstore SLSA build-provenance
  attestation on GHCR. Verify with the `gh attestation verify` commands
  shown in [Verifying the image](#verifying-the-image).
- Continuous checks: OpenSSF Scorecard, CodeQL Actions analysis,
  dependency review on PRs, and a daily Trivy CVE scan of the published
  image -- all surfaced in the GitHub *Security* tab.
- Repository hardening: run [`scripts/harden-repo.sh`](scripts/harden-repo.sh)
  once with admin `gh` auth -- it applies branch protection, secret
  scanning, push protection, private vulnerability reporting, and
  workflow-token restrictions in one shot. See
  [`.github/HARDENING.md`](.github/HARDENING.md) for what it does.

## License

BSD-3-Clause, matching upstream gopls. See [`LICENSE`](LICENSE). The
gopls binary inside the image stays under its own BSD-3-Clause license
from the Go project.
