# syntax=docker/dockerfile:1.7

FROM golang:1.26.2-alpine3.22 AS builder

# renovate: datasource=go depName=golang.org/x/tools/gopls
ARG GOPLS_VERSION=v0.21.1

RUN apk add --no-cache git \
 && go install golang.org/x/tools/gopls@${GOPLS_VERSION}

FROM golang:1.26.2-alpine3.22

RUN apk add --no-cache git ca-certificates \
 && addgroup -S gopls \
 && adduser -S -G gopls -h /home/gopls gopls \
 && mkdir -p /workspace \
 && chown gopls:gopls /workspace

COPY --from=builder /go/bin/gopls /usr/local/bin/gopls

USER gopls
WORKDIR /workspace
ENV GOPATH=/home/gopls/go \
    GOCACHE=/home/gopls/.cache/go-build \
    GOMODCACHE=/home/gopls/go/pkg/mod

LABEL org.opencontainers.image.title="gopls MCP server" \
      org.opencontainers.image.description="Go language server (gopls) exposed as a Model Context Protocol server" \
      org.opencontainers.image.source="https://github.com/davidgogl/gopls-mcp" \
      org.opencontainers.image.licenses="BSD-3-Clause" \
      org.opencontainers.image.vendor="David Gogl"

ENTRYPOINT ["gopls", "mcp"]
