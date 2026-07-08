#!/bin/bash
set -e

# Fetches the latest stable and beta Flutter versions and updates versions.json.
# The `latest` and `stable` tags both track the stable channel.

versions_file="versions.json"

releases_json=$(curl -s https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json)

# Fetches the latest version of a particular channel (stable, beta) for Flutter.
get_latest_version_in_channel() {
    channel=$1
    # Hash of the latest release in the channel.
    channel_hash=$(echo "$releases_json" | jq -r '.current_release.'"$channel")
    # Look up the version corresponding to that hash.
    version=$(echo "$releases_json" | jq -r --arg HASH "$channel_hash" \
        '.releases[] | select(.hash == $HASH).version')

    if [ -z "$version" ]; then
        echo "Error fetching latest version in channel $channel" >&2
        exit 1
    fi

    echo "$version"
}

stable_version=$(get_latest_version_in_channel "stable")
beta_version=$(get_latest_version_in_channel "beta")

echo "Latest stable version: $stable_version"
echo "Latest beta version: $beta_version"

tmp=$(mktemp)
jq --arg stable "$stable_version" --arg beta "$beta_version" \
    '.latest = $stable | .stable = $stable | .beta = $beta' \
    "$versions_file" > "$tmp" && mv "$tmp" "$versions_file"

exit 0
