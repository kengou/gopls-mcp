# Custom MCP catalog entry

`gopls.yaml` is the server entry for Docker Desktop's MCP Toolkit, in the
schema used by [`docker/mcp-registry`](https://github.com/docker/mcp-registry).
Use it to add this server to a private (custom) catalog, or as a starting
point for submitting to the public registry.

## Add to a custom catalog (CLI)

```bash
# 1. Create a catalog (only once). The OCI ref can be any registry you control.
docker mcp catalog create docker.io/davidgogl/mcp-catalog:latest \
  --title "David's MCP catalog"

# 2. Add the gopls server entry from this file.
docker mcp catalog server add docker.io/davidgogl/mcp-catalog:latest \
  --server-config ./gopls.yaml

# 3. Push the catalog so Docker Desktop (and others) can import it.
docker mcp catalog push docker.io/davidgogl/mcp-catalog:latest
```

## Import in Docker Desktop

1. Open Docker Desktop -> Extensions / MCP Toolkit -> **Catalogs**.
2. **Import catalog** -> paste the OCI ref you pushed
   (e.g. `docker.io/davidgogl/mcp-catalog:latest`).
3. Enable the **gopls** server. When prompted, set the **workspace**
   parameter to the absolute path of the Go project you want analyzed.

## Quick add without a catalog

If you just want to run the image once, skip the catalog and add it
directly:

```bash
docker mcp server add gopls \
  --image davidgogl/gopls-mcp:latest \
  --volume "$PWD:/workspace:ro"
```

## Submit to the public registry

A submission-ready set of files lives at
[`../mcp-registry/servers/gopls/`](../mcp-registry/servers/gopls/).
Fork [`docker/mcp-registry`](https://github.com/docker/mcp-registry),
copy that folder to `servers/gopls/`, fill in `source.commit` with the
commit being released, and open a PR.
