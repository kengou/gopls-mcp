# syntax=docker/dockerfile:1.23

FROM --platform=$BUILDPLATFORM golang:1.26.2-alpine3.22@sha256:7ef941168f213aa115df2e61364d67682129e99dc8188b734139dea862cc7d31 AS builder

ARG TARGETOS
ARG TARGETARCH

# renovate: datasource=go depName=golang.org/x/tools/gopls
ARG GOPLS_VERSION=v0.21.1

ENV CGO_ENABLED=0

RUN apk add --no-cache git
RUN GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go install golang.org/x/tools/gopls@${GOPLS_VERSION}
# go install drops the binary in /go/bin or /go/bin/${OS}_${ARCH}; normalize.
RUN install -D -m 0755 \
      "$(find /go/bin -name gopls -type f | head -n1)" \
      /out/gopls

FROM golang:1.26.2-alpine3.22@sha256:7ef941168f213aa115df2e61364d67682129e99dc8188b734139dea862cc7d31

RUN apk add --no-cache git ca-certificates \
 && addgroup -S gopls \
 && adduser -S -G gopls -h /home/gopls gopls \
 && mkdir -p /workspace \
 && chown gopls:gopls /workspace

COPY --from=builder /out/gopls /usr/local/bin/gopls

USER gopls
WORKDIR /workspace
ENV GOPATH=/home/gopls/go \
    GOCACHE=/home/gopls/.cache/go-build \
    GOMODCACHE=/home/gopls/go/pkg/mod

LABEL org.opencontainers.image.title="gopls MCP server" \
      org.opencontainers.image.description="Go language server (gopls) exposed as a Model Context Protocol server" \
      org.opencontainers.image.source="https://github.com/kengou/gopls-mcp" \
      org.opencontainers.image.licenses="BSD-3-Clause" \
      org.opencontainers.image.vendor="David Gogl"

ENTRYPOINT ["gopls", "mcp"]
