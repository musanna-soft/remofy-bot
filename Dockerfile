# syntax=docker/dockerfile:1.7

# ---- Stage 1: build the Go binary ------------------------------------------
FROM golang:1.24-alpine AS build
WORKDIR /src

# Cache modules first.
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -ldflags="-s -w" -o /out/remofy-bot ./cmd/bot

# ---- Stage 2: runtime ------------------------------------------------------
# Node 20 + the official @anthropic-ai/claude-code CLI. The bot probes
# `claude` on PATH and pipes prompts to its stdin (see internal/bot/claude.go).
FROM node:20-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates tini \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g @anthropic-ai/claude-code \
    && npm cache clean --force

WORKDIR /app
COPY --from=build /out/remofy-bot /app/remofy-bot

# Default workspace; override with BOT_WORKDIR from the k8s Deployment if needed.
ENV BOT_WORKDIR=/workspace
RUN mkdir -p /workspace

# tini reaps any zombie children claude may leave behind (Node + MCP servers).
ENTRYPOINT ["/usr/bin/tini", "--", "/app/remofy-bot"]
