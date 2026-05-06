# Security policy

## Reporting a vulnerability

Please **do not open a public issue** for security problems. Use
[GitHub's private vulnerability reporting][advisories] instead.

[advisories]: https://github.com/kengou/gopls-mcp/security/advisories/new

You should receive an acknowledgement within five business days. Once a
fix is verified it ships as a new image tag (which is automatically the
next gopls or base-image patch release picked up by Renovate). The fixed
tag is announced in a GitHub Security Advisory linked to a CVE when one
applies.

## Verifying images

Every published tag carries a Sigstore-backed SLSA build-provenance
attestation tied to a specific commit in this repository. The attestation
is attached to the GHCR copy because Docker Hub does not yet implement
the OCI 1.1 referrers API; the digest is identical in both registries,
so the same attestation verifies the Docker Hub copy too.

```bash
gh attestation verify oci://ghcr.io/kengou/gopls-mcp:<tag>     --owner kengou
gh attestation verify oci://docker.io/davidgogl/gopls-mcp:<tag> --owner kengou
```

## Out of scope

This image bundles upstream `gopls` and the Go toolchain. Vulnerabilities
in those projects should be reported to the Go project at
<https://go.dev/security/policy>; once they ship a fix it lands here
automatically via Renovate within a working day.
