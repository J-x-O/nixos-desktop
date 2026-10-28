#!/usr/bin/env bash
# Regenerates sources.json from the latest GitHub release of every craft app.
# usage: ./update.sh   (then rebuild)
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

repos=(
  storytold/photocraft storytold/vectorcraft storytold/filmcraft storytold/lightcraft
  storytold/pdfcraft storytold/effectcraft storytold/designcraft storytold/figcraft
  storytold/wordcraft storytold/soundcraft storytold/deckcraft storytold/cadcraft
  storytold/gridcraft tangency-labs/solidcraft
)

for repo in "${repos[@]}"; do
  curl -sfL ${GITHUB_TOKEN:+-H "Authorization: Bearer $GITHUB_TOKEN"} \
    "https://api.github.com/repos/$repo/releases/latest" | jq -c --arg name "${repo#*/}" '
      (.tag_name | ltrimstr("v")) as $version
      | (.assets[] | select(.name == "\($name)-\($version)-linux-x86_64.AppImage")) as $asset
      | { ($name): { version: $version, url: $asset.browser_download_url, digest: $asset.digest } }'
done | jq -s 'add' > sources.json.tmp

# github publishes hex sha256 digests, nix wants SRI
jq -r 'to_entries[] | "\(.key) \(.value.digest | ltrimstr("sha256:"))"' sources.json.tmp |
  while read -r name hex; do
    printf '%s %s\n' "$name" "$(nix hash convert --hash-algo sha256 --to sri "$hex")"
  done | jq -R -s 'split("\n") | map(select(. != "") | split(" ") | { (.[0]): .[1] }) | add' > hashes.json.tmp

jq --slurpfile h hashes.json.tmp '
  with_entries(.value = { version: .value.version, url: .value.url, hash: $h[0][.key] })' \
  sources.json.tmp > sources.json
rm sources.json.tmp hashes.json.tmp

jq -r 'to_entries[] | "\(.key)\t\(.value.version)"' sources.json | column -t
