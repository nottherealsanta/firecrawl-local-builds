#!/usr/bin/env bash
# Download a published release, verify every checksum, and run the binary for this machine.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
repo=${REPO:-nottherealsanta/firecrawl-local-builds}
version=${1:-$(tr -d '[:space:]' < "$root/VERSION")}
tag="v$version"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT INT TERM

command -v gh >/dev/null 2>&1 || { echo "gh is required: https://cli.github.com" >&2; exit 1; }

gh release download "$tag" --repo "$repo" --dir "$work"
cd "$work"

for name in \
  firecrawl-local-darwin-arm64 \
  firecrawl-local-darwin-amd64 \
  firecrawl-local-linux-arm64 \
  firecrawl-local-linux-amd64 \
  "firecrawl-local-$version.crate" \
  LICENSE NOTICE.md SOURCE.md SHA256SUMS; do
  [ -s "$name" ] || { echo "release is missing $name" >&2; exit 1; }
done

if command -v sha256sum >/dev/null 2>&1; then
  sha256sum -c SHA256SUMS
else
  shasum -a 256 -c SHA256SUMS
fi

case "$(uname -s)/$(uname -m)" in
  Darwin/arm64) asset=firecrawl-local-darwin-arm64 ;;
  Darwin/x86_64) asset=firecrawl-local-darwin-amd64 ;;
  Linux/x86_64) asset=firecrawl-local-linux-amd64 ;;
  Linux/aarch64|Linux/arm64) asset=firecrawl-local-linux-arm64 ;;
  *) asset= ;;
esac

if [ -n "$asset" ]; then
  chmod +x "$asset"
  "$asset" --version
fi

echo "Verified $tag from $repo"
