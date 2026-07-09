#!/usr/bin/env bash
#
# Build (and optionally push) the Flutter Docker images.
#
# Channel versions are read from versions.json (the single source of truth).
# This is the local build entrypoint. CI builds each architecture on native
# runners (Flutter's Dart VM aborts under QEMU emulation) but reads the same
# versions.json, so local and CI never drift on which version each tag ships.
#
# Usage:
#   ./build.sh [CHANNEL...]              Build the given channels for the host
#                                        architecture and load them into Docker.
#                                        With no arguments, builds every channel.
#
#   PUSH=true ./build.sh [CHANNEL...]    Build multi-arch images and push them to
#                                        the registry. Requires a prior `docker login`.
#
# Channels are the keys in versions.json: latest, stable, beta.
#
# Environment variables:
#   PUSH        "true" to push to the registry. Default: false (loads locally).
#   IMAGE       Image repository. Default: ghcr.io/steffensenchyna/flutter
#   PLATFORMS   Comma-separated buildx platforms. Default: host arch for local
#               builds, "linux/amd64,linux/arm64" when pushing. Note: a local
#               --load build can only target a single platform.

set -euo pipefail

cd "$(dirname "$0")"

IMAGE="${IMAGE:-ghcr.io/steffensenchyna/flutter}"
PUSH="${PUSH:-false}"
VERSIONS_FILE="versions.json"

command -v jq >/dev/null 2>&1 || { echo "error: jq is required but not installed" >&2; exit 1; }

# Which channels to build: explicit args, or all keys in versions.json.
channels=()
if [ "$#" -gt 0 ]; then
    channels=("$@")
else
    while IFS= read -r channel; do
        channels+=("$channel")
    done < <(jq -r 'keys[]' "$VERSIONS_FILE")
fi

# Decide platforms, output mode, and (for multi-arch) the builder to use.
builder_flag=()
if [ "$PUSH" = "true" ]; then
    platforms="${PLATFORMS:-linux/amd64,linux/arm64}"
    output_flag="--push"
    # Multi-arch requires a container-driver builder; create one on first use.
    if ! docker buildx inspect multibuilder >/dev/null 2>&1; then
        docker buildx create --name multibuilder --driver docker-container --bootstrap >/dev/null
    fi
    builder_flag=(--builder multibuilder)
else
    platforms="${PLATFORMS:-}"
    output_flag="--load"
fi

for channel in "${channels[@]}"; do
    version="$(jq -r --arg c "$channel" '.[$c] // empty' "$VERSIONS_FILE")"
    if [ -z "$version" ]; then
        echo "error: unknown channel '$channel' (not found in $VERSIONS_FILE)" >&2
        exit 1
    fi

    # Docker tags cannot contain '+', which Flutter uses for build metadata.
    version_tag="${version//+/-}"

    echo "==> Building $IMAGE:$channel (Flutter $version)"

    args=(buildx build "${builder_flag[@]}"
        --build-arg "flutter_version=$version"
        --tag "$IMAGE:$channel"
        --tag "$IMAGE:$version_tag"
        "$output_flag")

    if [ -n "$platforms" ]; then
        args+=(--platform "$platforms")
    fi

    args+=(sdk)

    docker "${args[@]}"
done
