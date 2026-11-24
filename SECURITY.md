# Security

## Supported releases

Only the newest published release is supported. Each release is tagged `v<version>` and carries `SHA256SUMS`, the
exact source archive, the AGPL-3.0 licence and GitHub-signed build-provenance attestations.

## Report a vulnerability

Use GitHub's private vulnerability reporting on this repository
(<https://github.com/nottherealsanta/firecrawl-local-builds/security/advisories/new>). If the report does not need to
stay private, a normal issue is fine. Do not attach malware; describe it and give a hash.

Security problems in Firecrawl Local itself belong upstream:
<https://github.com/firecrawl/firecrawl/security>.

## What is checked before a binary is published

- The tag must be exactly `v<VERSION>`, and `VERSION` must match the pin in `pins/<version>.env`.
- The crates.io API checksum, the pinned checksum and the downloaded archive must agree.
- The version must not be yanked and its declared licence must be `AGPL-3.0`.
- The archive's `.cargo_vcs_info.json` commit must match the pin.
- The upstream `LICENSE` at that commit must match its pinned SHA-256.
- The crate is built with its own `Cargo.lock` (`cargo build --release --locked`), a clean `CARGO_HOME` and the
  exact pinned Rust toolchain.
- The binary must print the pinned version, respond to `--help`, and match the runner's OS and architecture.
- On Linux amd64 the build is repeated from scratch; the two binaries must be byte-identical.
- Every binary is attested with `actions/attest-build-provenance`. `SHA256SUMS` covers every release file.
- The release job downloads its own published assets and verifies `SHA256SUMS` again.

## Supply-chain precautions

- All third-party actions are pinned to full commit SHAs, with the release tag in a comment. Renovation is a
  deliberate commit.
- The workflow only runs on tag pushes and manual `workflow_dispatch`. There is no `pull_request` or
  `pull_request_target` build, so unreviewed code never runs with a write token.
- Top-level permissions are `contents: read`. Only the release job gets `contents: write`; only jobs that attest get
  `id-token: write` and `attestations: write`.
- `actions/checkout` uses `persist-credentials: false`, so the token is not left in `.git/config`.
- The build job has no repository write permission and no secrets.
- The crates are downloaded over HTTPS from crates.io and checked against both the crates.io metadata checksum and
  the committed pin. `Cargo.lock` pins and checksums every transitive dependency.
- A published release is never overwritten. A rerun can complete a draft, but refuses to upload over a public
  release.

## Limits and trust anchors

- **The GitHub account and repository are trusted.** Someone who can push a `v*` tag or edit the workflow can run
  the build. Protect the account, use two-factor authentication, and keep tag creation limited to maintainers.
- **GitHub-hosted runners and their images are trusted.** A compromised runner could produce a malicious binary that
  still has a valid attestation. The attestation proves which workflow, commit and runner image produced an asset;
  it does not prove the runner was honest.
- **Runner images change.** Byte-identical rebuilds are enforced within one run on one image, not across image
  versions. Compare `SHA256SUMS` when reproducing elsewhere.
- **Release assets are mutable to a repository administrator.** If an asset is replaced, its checksum changes too,
  and the old attestation no longer matches. `gh attestation verify` is the way to detect that: it checks the file
  against the attestation GitHub recorded for this repository.
- **The binaries run with the user's privileges.** They are not sandboxed by this repository. Nexus starts the
  server with Firecrawl cloud hand-off off and public-address-only defaults; that is a Nexus policy, not a property
  of these builds.

## Verify a download

```sh
gh attestation verify firecrawl-local-linux-amd64 \
  --repo nottherealsanta/firecrawl-local-builds
```

Offline, with the release's `SHA256SUMS` beside the file:

```sh
grep ' firecrawl-local-linux-amd64$' SHA256SUMS | sha256sum -c -
```

On macOS use `shasum -a 256 -c -`.
