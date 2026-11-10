#!/usr/bin/env python3
"""Read-only input/cache diagnostics; no Nix, credentials, or lock-file writes."""
import argparse
import concurrent.futures
import json
from pathlib import Path
import re
import urllib.error
import urllib.request

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--offline", action="store_true", help="Only check input/lock consistency")
args = parser.parse_args()
flake = (root / "flake.nix").read_text()
lock = json.loads((root / "flake.lock").read_text())
declared = {
    "nixpkgs": re.search(r'nixpkgs\.url\s*=\s*"([^"]+)"', flake).group(1),
    "home-manager": re.search(r'home-manager\s*=\s*\{\s*(?://[^\n]*\n|#[^\n]*\n|\s)*url\s*=\s*"([^"]+)"', flake).group(1),
}
probes = []
problems = []
for name, url in declared.items():
    match = re.fullmatch(r"github:([^/]+)/([^/]+)/([^?]+)", url)
    if not match:
        problems.append(f"{name}: unsupported diagnostic URL format; inspect manually: {url}")
        continue
    owner, repo, ref = match.groups()
    original = {"type": "github", "owner": owner, "repo": repo}
    original["rev" if re.fullmatch(r"[0-9a-f]{40}", ref) else "ref"] = ref
    node_key = lock["nodes"][lock["root"]]["inputs"].get(name)
    node = lock["nodes"].get(node_key, {}) if isinstance(node_key, str) else {}
    if not node:
        problems.append(f"{name}: missing lock entry; run nix flake lock on a Nix-enabled machine")
    elif node.get("original") != original:
        problems.append(f"{name}: flake.nix does not match lock.original")
    locked = node.get("locked", {})
    revision = locked.get("rev", ref)
    if node and not locked.get("narHash"):
        problems.append(f"{name}: missing NAR integrity hash")
    print(f"INPUT {name}: {url}\n  audited/download revision: {revision}")
    probes.extend([
        (f"{name} GitHub API", f"https://api.github.com/repos/{owner}/{repo}/tarball/{revision}"),
        (f"{name} codeload alternative", f"https://codeload.github.com/{owner}/{repo}/tar.gz/{revision}"),
    ])
    if name == "home-manager" and node:
        if node.get("inputs", {}).get("nixpkgs") != ["nixpkgs"]:
            problems.append("home-manager.nixpkgs must follow the root nixpkgs input")

probes.extend([
    ("USTC binary cache", "https://mirrors.ustc.edu.cn/nix-channels/store/nix-cache-info"),
    ("official binary cache", "https://cache.nixos.org/nix-cache-info"),
])

def probe(item):
    label, url = item
    request = urllib.request.Request(url, headers={"User-Agent": "dotfiles-network-check", "Range": "bytes=0-1023"})
    try:
        with urllib.request.urlopen(request, timeout=25) as response:
            sample = response.read(1024)
            if label.endswith("binary cache") and b"StoreDir: /nix/store" not in sample:
                return False, f"FAIL {label}: response is not nix-cache-info ({url})"
            if "text/html" in response.headers.get("Content-Type", ""):
                return False, f"FAIL {label}: HTML response instead of source/cache data ({url})"
            return True, f"OK {label}: HTTP {response.status} ({url})"
    except (urllib.error.URLError, TimeoutError, OSError) as error:
        return False, f"FAIL {label}: {error} ({url})"

failures = 0
if not args.offline:
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
        for ok, message in pool.map(probe, probes):
            print(message)
            failures += not ok
for problem in problems:
    print("BLOCKED " + problem)
print("HTTP reachability does not verify NAR hashes, substitutions, or Nix evaluation.")
raise SystemExit(2 if problems else 1 if failures else 0)
