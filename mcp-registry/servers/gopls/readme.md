# gopls

The official Go language server, [`gopls`](https://pkg.go.dev/golang.org/x/tools/gopls),
exposed over the Model Context Protocol. Lets MCP clients explore Go
workspaces structurally instead of grepping.

## Tools

| Tool | What it does |
| --- | --- |
| `go_workspace` | Detect module / `go.work` / GOPATH layout |
| `go_search` | Fuzzy symbol search across the workspace |
| `go_file_context` | Summary of intra-package dependencies of a file |
| `go_package_api` | Exported API of one or more packages |
| `go_symbol_references` | All references to a symbol -- run before edits |
| `go_diagnostics` | Build and analysis errors with quick-fix diffs |
| `go_vulncheck` | govulncheck on a package pattern |

## Configuration

Mount the Go workspace you want analyzed at `/workspace` inside the
container. The image runs as a non-root `gopls` user, so the mount must
be readable by that user. A read-only mount is enough unless you want
gopls quick-fixes applied in place.

| Parameter | Required | Description |
| --- | --- | --- |
| `workspace` | yes | Absolute host path to the Go workspace |

## Example client config

Claude Desktop / Claude Code:

```json
{
  "mcpServers": {
    "gopls": {
      "command": "docker",
      "args": [
        "run", "--rm", "-i",
        "-v", "/abs/path/to/workspace:/workspace:ro",
        "davidgogl/gopls-mcp:latest"
      ]
    }
  }
}
```

## Notes

- The image carries a full Go toolchain at runtime because gopls shells
  out to `go list`, `go build`, etc.
- Multi-arch: `linux/amd64`, `linux/arm64`.
- Image tag tracks the upstream gopls version (e.g. `v0.21.1`).
- Source: <https://github.com/kengou/gopls-mcp>.
