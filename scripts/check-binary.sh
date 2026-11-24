#!/usr/bin/env bash
# Check a built firecrawl-local binary: it runs, reports the pinned version and matches its target OS/architecture.
set -euo pipefail

if [ "$#" -ne 4 ]; then
  echo "usage: $0 <binary> <darwin|linux> <arm64|amd64> <version>" >&2
  exit 2
fi

binary=$1
expected_os=$2
expected_arch=$3
version=$4

case "$(uname -s)" in
  Darwin) host_os=darwin ;;
  Linux) host_os=linux ;;
  *) echo "unsupported host: $(uname -s)" >&2; exit 1 ;;
esac
case "$(uname -m)" in
  arm64|aarch64) host_arch=arm64 ;;
  x86_64|amd64) host_arch=amd64 ;;
  *) echo "unsupported machine: $(uname -m)" >&2; exit 1 ;;
esac

if [ "$host_os" != "$expected_os" ] || [ "$host_arch" != "$expected_arch" ]; then
  echo "cannot check $expected_os-$expected_arch on $host_os-$host_arch" >&2
  exit 1
fi

[ -f "$binary" ] || { echo "missing $binary" >&2; exit 1; }
[ -x "$binary" ] || { echo "$binary is not executable" >&2; exit 1; }

reported=$("$binary" --version)
printf '%s\n' "$reported"
case "$reported" in
  *"$version"*) ;;
  *) echo "expected version $version, got: $reported" >&2; exit 1 ;;
esac

"$binary" --help >/dev/null

kind=$(file -b "$binary")
case "$expected_os/$expected_arch" in
  linux/amd64)
    case "$kind" in
      *ELF*64-bit*x86-64*) ;;
      *) echo "not an x86-64 Linux ELF: $kind" >&2; exit 1 ;;
    esac
    ;;
  linux/arm64)
    case "$kind" in
      *ELF*64-bit*aarch64*) ;;
      *) echo "not an arm64 Linux ELF: $kind" >&2; exit 1 ;;
    esac
    ;;
  darwin/amd64)
    case "$kind" in
      *Mach-O*64-bit*x86_64*) ;;
      *) echo "not an x86_64 Mach-O: $kind" >&2; exit 1 ;;
    esac
    ;;
  darwin/arm64)
    case "$kind" in
      *Mach-O*64-bit*arm64*) ;;
      *) echo "not an arm64 Mach-O: $kind" >&2; exit 1 ;;
    esac
    ;;
esac

if [ "$host_os" = linux ]; then
  ldd_out=$(ldd "$binary")
  if printf '%s\n' "$ldd_out" | grep -q 'not found'; then
    printf '%s\n' "$ldd_out" >&2
    echo "the binary has unresolved shared libraries" >&2
    exit 1
  fi
fi

if [ "$host_os" = darwin ]; then
  # Rust ad-hoc signs arm64 binaries; Intel builds may be unsigned. Warn, do not fail.
  if ! codesign --verify --strict "$binary" >/dev/null 2>&1; then
    echo "warning: no valid code signature (the binary still runs on this machine)" >&2
  fi
fi
