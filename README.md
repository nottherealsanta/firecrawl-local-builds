# firecrawl-local-builds

Prebuilt, unmodified [`firecrawl-local`](https://github.com/firecrawl/firecrawl/tree/main/apps/local) binaries for
Nexus and for anyone else who wants the scraper without a Rust toolchain.

The binaries are built from the pinned crate on crates.io, never from a fork. Each release also carries the exact
crate source it was built from, the upstream AGPL-3.0 licence, SHA-256 checksums and GitHub build-provenance
attestations.

## Releases

Each version is a GitHub release tagged `v<version>`. Current pin: **0.1.1** (see [`VERSION`](VERSION)).

Published asset names:

| Asset | Platform |
| --- | --- |
| `firecrawl-local-darwin-arm64` | macOS, Apple silicon |
| `firecrawl-local-darwin-amd64` | macOS, Intel |
| `firecrawl-local-linux-arm64` | Linux (glibc), arm64 |
| `firecrawl-local-linux-amd64` | Linux (glibc), x86-64 |
| `SHA256SUMS` | SHA-256 of every binary, the source crate and the notices |
| `firecrawl-local-<version>.crate` | exact crates.io source the binaries were built from |
| `LICENSE` | upstream AGPL-3.0 licence |
| `NOTICE.md`, `SOURCE.md` | attribution and source-offer details |

There are no Windows or musl builds. Linux binaries are built on Ubuntu 22.04 (glibc 2.35), so they need glibc 2.35
or newer. macOS binaries target macOS 13 or newer.

Release URL pattern:

```text
https://github.com/nottherealsanta/firecrawl-local-builds/releases/download/v0.1.1/firecrawl-local-linux-amd64
https://github.com/nottherealsanta/firecrawl-local-builds/releases/download/v0.1.1/SHA256SUMS
```

## Install and verify

Linux x86-64:

```sh
version=0.1.1
base="https://github.com/nottherealsanta/firecrawl-local-builds/releases/download/v$version"

curl -fsSLO "$base/firecrawl-local-linux-amd64"
curl -fsSLO "$base/SHA256SUMS"
grep ' firecrawl-local-linux-amd64$' SHA256SUMS | sha256sum -c -
mkdir -p "$HOME/.local/bin"
install -m 755 firecrawl-local-linux-amd64 "$HOME/.local/bin/firecrawl-local"
firecrawl-local --version
```

On macOS use `shasum -a 256 -c -` instead of `sha256sum -c -`, and choose `firecrawl-local-darwin-arm64` or
`firecrawl-local-darwin-amd64`. A browser download may add the quarantine attribute; `curl` does not. If macOS
refuses the binary, run `xattr -d com.apple.quarantine <path>` after checking the checksum.

The arm64 macOS binary is ad-hoc signed by the linker; the Intel macOS binary is unsigned. Both were run on their
native runners before the release. Neither is notarized by an Apple Developer ID, so verify `SHA256SUMS` and the
attestation rather than relying on Gatekeeper.

Verify the provenance record GitHub signed for the workflow run:

```sh
gh attestation verify firecrawl-local-linux-amd64 \
  --repo nottherealsanta/firecrawl-local-builds
```

Or verify a whole downloaded release (assets, checksums and the matching local binary):

```sh
scripts/verify-release.sh 0.1.1
```

## Licence and source

`firecrawl-local` is Copyright Firecrawl (Mendable AI, Inc.) and licensed under the **GNU Affero General Public
License, version 3 (AGPL-3.0)**. This repository does not modify its source.

- Upstream: <https://github.com/firecrawl/firecrawl>, `apps/local`
- Crate: <https://crates.io/crates/firecrawl-local/0.1.1>
- Pinned crate SHA-256: `5a0f837d8b3687aab45c6d4ad5c2dddf21849c883501e24145df4c32787be964`
- Crate VCS commit: `7c16513e6ada9df5d9a6cfa6a1a1cfda3c841f9d`
- Licence: AGPL-3.0. The full upstream licence text is attached to every release as `LICENSE` and is also at
  <https://www.gnu.org/licenses/agpl-3.0.txt>; [`LICENSE`](LICENSE) in this repository is the licence notice for
  the build scripts.

Every release attaches the exact `.crate` archive that was compiled, so the corresponding source travels with the
binaries. The upstream repository at the pinned commit is the other source location. See [`NOTICE.md`](NOTICE.md)
and [`SECURITY.md`](SECURITY.md).

Nexus runs the binary as a separate process and talks to it over HTTP on a loopback address; it does not link the
code. The licence of this repository's own build scripts is AGPL-3.0 as well, to keep the distribution simple.

## How a build is made

1. `VERSION` selects the crate version. `pins/<version>.env` pins the crates.io archive SHA-256, the source commit,
   the Rust toolchain, `SOURCE_DATE_EPOCH` and the upstream licence hash. `rust-toolchain.toml` makes rustup use the
   same exact toolchain for every command in the repository.
2. The workflow checks the tag (`v<version>`), fetches crates.io metadata and refuses the build unless the
   crates.io checksum, the pinned checksum and the archive agree. It also checks that the version is not yanked,
   that the licence is `AGPL-3.0`, and that the archive's `.cargo_vcs_info.json` matches the pinned commit.
3. A job-local `CARGO_HOME` is used, the crate's own `Cargo.lock` is enforced with `cargo build --release --locked`,
   and the Rust toolchain is installed at the exact pinned version.
4. Paths are remapped (`/build`, `/cargo`), `SOURCE_DATE_EPOCH` is fixed, `CARGO_INCREMENTAL=0` and
   `ZERO_AR_DATE=1` are set. The crate's upstream release profile (`lto = "fat"`, `codegen-units = 1`,
   `strip = true`) is unchanged.
5. Each binary is run (`--version`, `--help`), checked against the host OS/architecture with `file`, and on Linux
   checked with `ldd`. On Linux amd64 the build is repeated from scratch and the two files must be byte-identical.
6. The workflow attests each binary, then generates `SHA256SUMS` over all release files. The release job downloads
   the published assets again and verifies them before finishing.

Bit-for-bit reproducibility is required between the two builds on the same GitHub runner image. It is not claimed
across different runner image versions, because Apple's and Canonical's toolchains change underneath the pinned
Rust version. The checksums and provenance attestations are the trust anchor for each published build.

Local reproduction:

```sh
rustup toolchain install 1.100.0
rustup default 1.100.0
scripts/build-local.sh
```

That writes `dist/firecrawl-local-<os>-<arch>` and prints its SHA-256. It downloads dependencies into an isolated
temporary `CARGO_HOME` by default; set `FC_CARGO_HOME` to reuse one. The script also needs `curl`, `tar`, `file`
and Python 3 for the source checks.

## Updating the pinned version

1. Put the new version in `VERSION` and add `pins/<version>.env` with the crates.io checksum, VCS commit, licence
   hash and toolchain. Update `rust-toolchain.toml` to the same toolchain.
2. Run `scripts/build-local.sh` on at least one platform and check the binary.
3. Run the workflow manually (`workflow_dispatch`) for a dry run; it builds every platform but does not publish.
4. Commit, push `main`, then push the tag `v<version>`. The tag run publishes the release.

A published release is never replaced. A rerun can finish an existing **draft** release, but it refuses to overwrite
a release that is already public. To correct a published release, publish a new version.

## Nexus integration

Nexus's `install.sh` at `HEAD` looks for `firecrawl-local-<os>-<arch>` inside **Nexus's own** release and verifies
it against that release's `SHA256SUMS`. These assets use the same names and the same `SHA256SUMS` format, so the
installer can use this repository if it is given a separate base URL, for example:

```text
NEXUS_FIRECRAWL_BASE=https://github.com/nottherealsanta/firecrawl-local-builds/releases/download/v0.1.1
```

Two changes are needed in `install.sh`, not just the extra base URL:

1. It must fetch `SHA256SUMS` from that base and verify the binary against it. It cannot reuse
   `NEXUS_RELEASE_BASE`, because the Nexus release and this release are different releases with different
   checksum files (and this release has no TUI, wheel or web bundle).
2. It must map `uname -m` to these asset names. `HEAD` computes `fc="firecrawl-local-$os-$(uname -m)"`, which
   gives `x86_64` on Linux x86-64 and `aarch64` on Linux arm64, but these assets are `amd64` and `arm64`
   respectively. macOS already reports `arm64`/`x86_64`, so `x86_64` still needs mapping to `amd64`. The mapping
   is:

   ```text
   x86_64|amd64   -> amd64
   arm64|aarch64  -> arm64
   ```

As of 2026-11-24 the Nexus working tree no longer installs a `firecrawl-local` binary at all (it runs the
Firecrawl container), so wiring this in is a decision for the Nexus installer owner.

The Firecrawl tool in Nexus pins the crate version in `nexus-core/nexus/firecrawl.py` (`VERSION`). Keep that value
and this repository's `VERSION` in step.

## Security

See [`SECURITY.md`](SECURITY.md). Report a problem through GitHub's private vulnerability reporting for this
repository, or open a public issue if the report does not need to stay private.
