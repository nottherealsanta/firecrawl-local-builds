#!/usr/bin/env python3
"""Check that an unpacked firecrawl-local crate is exactly the pinned source."""
import json
import pathlib
import re
import sys


def main() -> int:
    if len(sys.argv) != 4:
        print("usage: check-source.py <unpacked-crate> <version> <commit>", file=sys.stderr)
        return 2
    src, version, commit = sys.argv[1:4]
    root = pathlib.Path(src)

    for required in ("Cargo.toml", "Cargo.lock", "build.rs", "src/native/html.rs"):
        if not (root / required).is_file():
            print(f"source archive is missing {required}", file=sys.stderr)
            return 1

    cargo = (root / "Cargo.toml").read_text(encoding="utf-8")
    name = re.search(r'^name = "([^"]+)"$', cargo, re.MULTILINE)
    got = re.search(r'^version = "([^"]+)"$', cargo, re.MULTILINE)
    if not name or name.group(1) != "firecrawl-local":
        print("source archive is not firecrawl-local", file=sys.stderr)
        return 1
    if not got or got.group(1) != version:
        print(f"source archive version {got.group(1) if got else '?'} is not {version}", file=sys.stderr)
        return 1

    info = json.loads((root / ".cargo_vcs_info.json").read_text(encoding="utf-8"))
    git = info.get("git", {})
    if git.get("sha1") != commit:
        print(f"source archive commit {git.get('sha1')} is not pinned {commit}", file=sys.stderr)
        return 1
    if info.get("path_in_vcs") != "apps/local":
        print(f"source archive path is not apps/local: {info.get('path_in_vcs')}", file=sys.stderr)
        return 1

    print(f"source archive is firecrawl-local {version} at {commit}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
