# Third-party notice

This repository distributes unmodified binaries of **Firecrawl Local**.

- **Project:** Firecrawl Local, part of Firecrawl, by Mendable AI, Inc. (Firecrawl)
- **Upstream:** <https://github.com/firecrawl/firecrawl>, directory `apps/local`
- **Crate:** `firecrawl-local` on crates.io
- **Licence:** GNU Affero General Public License, version 3 (AGPL-3.0). The full upstream licence text is attached
  to every release as `LICENSE`, and is also at <https://www.gnu.org/licenses/agpl-3.0.txt>. The repository's
  [`LICENSE`](LICENSE) is the licence notice for the build scripts.
- **Copyright:** Firecrawl / Mendable AI, Inc. and contributors.

## Pinned source

| | |
| --- | --- |
| Version | `0.1.1` |
| Crate archive | <https://static.crates.io/crates/firecrawl-local/firecrawl-local-0.1.1.crate> |
| Crate SHA-256 | `5a0f837d8b3687aab45c6d4ad5c2dddf21849c883501e24145df4c32787be964` |
| Crate VCS commit | `7c16513e6ada9df5d9a6cfa6a1a1cfda3c841f9d` |
| Upstream source | <https://github.com/firecrawl/firecrawl/tree/7c16513e6ada9df5d9a6cfa6a1a1cfda3c841f9d/apps/local> |

Each release attaches that exact `.crate` archive as `firecrawl-local-0.1.1.crate`, so the corresponding source is
available from the same release as the binaries. The upstream repository at the pinned commit is an equivalent
source location; the crate also vendors the shared `apps/api/native` sources that the published package cannot
reference outside its own directory.

## Changes

None. The binaries are built from the unmodified crates.io archive. The only build-time settings are the pinned
Rust toolchain, `--locked`, a fixed `SOURCE_DATE_EPOCH`, path remapping for reproducible diagnostics, and the
upstream release profile already declared in the crate (`lto = "fat"`, `codegen-units = 1`, `strip = true`).

Nexus runs the binary as a separate child process and communicates over HTTP on a loopback address. It does not
link the code, so this distribution does not change Nexus's own licensing position. This notice is not legal
advice.

## Redistribution

The AGPL-3.0 permits redistribution of unmodified binaries provided the licence and corresponding source are made
available. This repository keeps the full licence text, the exact source archive and the build recipe together in
each release. If you redistribute a binary, keep those files with it and preserve this notice.
