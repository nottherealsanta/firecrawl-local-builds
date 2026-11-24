#!/usr/bin/env bash
# Build the pinned firecrawl-local crate for this machine, from the exact crates.io archive.
# CI runs this same script; see README.md for the release workflow.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
version=$(tr -d '[:space:]' < "$root/VERSION")
pin="$root/pins/$version.env"
[ -f "$pin" ] || { echo "missing pin: $pin" >&2; exit 1; }

# shellcheck source=/dev/null
set -a
. "$pin"
set +a

if [ "$FIRECRAWL_VERSION" != "$version" ]; then
  echo "VERSION ($version) and $pin ($FIRECRAWL_VERSION) disagree" >&2
  exit 1
fi

toolchain_channel=$(sed -n 's/^channel = "\(.*\)"$/\1/p' "$root/rust-toolchain.toml")
if [ "$toolchain_channel" != "$RUST_VERSION" ]; then
  echo "rust-toolchain.toml ($toolchain_channel) and $pin ($RUST_VERSION) disagree" >&2
  exit 1
fi

command -v rustc >/dev/null 2>&1 || { echo "rustc not found; install Rust from https://rustup.rs" >&2; exit 1; }
actual_rust=$(rustc --version | awk '{print $2}')
if [ "$actual_rust" != "$RUST_VERSION" ]; then
  echo "Rust $RUST_VERSION is required (found $actual_rust)." >&2
  echo "Run: rustup toolchain install $RUST_VERSION && rustup default $RUST_VERSION" >&2
  exit 1
fi

case "$(uname -s)/$(uname -m)" in
  Darwin/arm64) os=darwin; arch=arm64 ;;
  Darwin/x86_64) os=darwin; arch=amd64 ;;
  Linux/x86_64) os=linux; arch=amd64 ;;
  Linux/aarch64|Linux/arm64) os=linux; arch=arm64 ;;
  *) echo "unsupported platform: $(uname -s) $(uname -m)" >&2; exit 1 ;;
esac

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT INT TERM
umask 022

crate="$work/firecrawl-local-$version.crate"
crate_url="https://static.crates.io/crates/firecrawl-local/firecrawl-local-$version.crate"
ua="firecrawl-local-builds (https://github.com/nottherealsanta/firecrawl-local-builds)"
curl -fsSL --retry 3 --proto '=https' --tlsv1.2 -A "$ua" "$crate_url" -o "$crate"

# The crates.io API checksum and the committed pin must both match the archive.
meta_url="https://crates.io/api/v1/crates/firecrawl-local/$version"
if ! api_sha=$(curl -fsSL --retry 3 --proto '=https' --tlsv1.2 -A "$ua" "$meta_url" |
  python3 -c 'import json, sys; print(json.load(sys.stdin)["version"]["checksum"])'); then
  echo "could not read the crates.io metadata for firecrawl-local $version" >&2
  exit 1
fi
if [ "${#api_sha}" -ne 64 ] || printf '%s' "$api_sha" | grep -q '[^0-9a-f]'; then
  echo "crates.io returned an invalid checksum: $api_sha" >&2
  exit 1
fi
if [ "$api_sha" != "$CRATE_SHA256" ]; then
  echo "crates.io checksum $api_sha does not match pin $CRATE_SHA256" >&2
  exit 1
fi
if command -v sha256sum >/dev/null 2>&1; then
  printf '%s  %s\n' "$CRATE_SHA256" "$crate" | sha256sum -c -
else
  printf '%s  %s\n' "$CRATE_SHA256" "$crate" | shasum -a 256 -c -
fi

mkdir -p "$work/build"
tar -xzf "$crate" -C "$work/build"
src="$work/build/firecrawl-local-$version"

python3 "$root/scripts/check-source.py" "$src" "$version" "$CRATE_VCS_COMMIT"

export CARGO_HOME="${FC_CARGO_HOME:-$work/cargo-home}"
mkdir -p "$CARGO_HOME"
export CARGO_INCREMENTAL=0
export CARGO_TERM_COLOR=never
export SOURCE_DATE_EPOCH
# Keep the build inside this temporary tree, even when a parent process points Cargo at a shared build directory.
unset CARGO_BUILD_BUILD_DIR CARGO_BUILD_TARGET_DIR
export CARGO_TARGET_DIR="$src/target"
export RUSTFLAGS="--remap-path-prefix=$work/build=/build --remap-path-prefix=$CARGO_HOME=/cargo"
if [ "$os" = darwin ]; then
  export MACOSX_DEPLOYMENT_TARGET=13.0
  export ZERO_AR_DATE=1
fi

echo "› Building firecrawl-local $version for $os-$arch with Rust $RUST_VERSION" >&2
(cd "$src" && cargo build --release --locked)

mkdir -p "$root/dist"
binary="$root/dist/firecrawl-local-$os-$arch"
install -m 755 "$src/target/release/firecrawl-local" "$binary"
"$root/scripts/check-binary.sh" "$binary" "$os" "$arch" "$version"

echo "› $binary"
if command -v sha256sum >/dev/null 2>&1; then
  (cd "$root/dist" && sha256sum "firecrawl-local-$os-$arch")
else
  (cd "$root/dist" && shasum -a 256 "firecrawl-local-$os-$arch")
fi
