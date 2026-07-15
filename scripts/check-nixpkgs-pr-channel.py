#!/usr/bin/env python3
"""Check whether nixpkgs PRs have reached a channel branch.

Examples:
    python3 scripts/check-nixpkgs-pr-channel.py 536365
    python3 scripts/check-nixpkgs-pr-channel.py 536365 -t nixpkgs-unstable
    python3 scripts/check-nixpkgs-pr-channel.py --overlay -t nixos-unstable

Set GITHUB_TOKEN to avoid GitHub's low unauthenticated rate limit.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any

REPO = Path(__file__).resolve().parent.parent
OVERLAY = REPO / "modules" / "overlays" / "default.nix"

OWNER = "NixOS"
PROJECT = "nixpkgs"
API_ROOT = f"https://api.github.com/repos/{OWNER}/{PROJECT}"
USER_AGENT = "nix-conf-pr-channel-check"
DEFAULT_TARGET = "nixos-unstable"
PR_TRACKER_RE = re.compile(r"pr-tracker:\s+(?:nixpkgs)?#(?P<number>\d{4,})(?P<rest>.*)")
TARGET_RE = re.compile(r"\btarget=([A-Za-z0-9_.+/-]+)")
PACKAGE_RE = re.compile(r"\bpackage=([A-Za-z0-9_.+/-]+)")

NEXT_BRANCH_TABLE = [
    (r"\Astaging\Z", ["staging-next"]),
    (r"\Astaging-next\Z", ["master"]),
    (r"\Astaging-next-([\d.]+)\Z", ["release-\\1"]),
    (r"\Ahaskell-updates\Z", ["staging"]),
    (r"\Amaster\Z", ["nixpkgs-unstable", "nixos-unstable-small"]),
    (r"\Anixos-(.*)-small\Z", ["nixos-\\1"]),
    (r"\Arelease-([\d.]+)\Z", ["nixpkgs-\\1-darwin", "nixos-\\1-small"]),
    (r"\Astaging-((1.|20)\.\d{2})\Z", ["release-\\1"]),
    (r"\Astaging-((2[1-9]|[3-90].)\.\d{2})\Z", ["staging-next-\\1"]),
    (r"\Astaging-nixos\Z", ["master"]),
]


@dataclass(frozen=True)
class PullRequest:
    number: int
    title: str
    base_branch: str
    state: str
    merged_at: str | None
    merge_commit_sha: str | None

    @property
    def merged(self) -> bool:
        return self.merged_at is not None


@dataclass(frozen=True)
class OverlayMarker:
    number: int
    targets: tuple[str, ...]
    package: str | None
    source: str


class GitHubError(RuntimeError):
    pass


class GitHubHTTPError(GitHubError):
    def __init__(self, status: int, message: str):
        super().__init__(f"GitHub API returned {status}: {message}")
        self.status = status


class NotPullRequest(GitHubError):
    pass


def github_headers() -> dict[str, str]:
    headers = {
        "Accept": "application/vnd.github+json",
        "User-Agent": USER_AGENT,
        "X-GitHub-Api-Version": "2022-11-28",
    }

    token = os.environ.get("GITHUB_TOKEN")
    if token:
        headers["Authorization"] = f"Bearer {token}"

    return headers


def github_get(path: str) -> Any:
    request = urllib.request.Request(f"{API_ROOT}{path}", headers=github_headers())
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        body = error.read().decode("utf-8", errors="replace")
        try:
            message = json.loads(body).get("message", body.strip())
        except json.JSONDecodeError:
            message = body.strip()
        raise GitHubHTTPError(error.code, message) from error
    except urllib.error.URLError as error:
        raise GitHubError(f"GitHub API request failed: {error.reason}") from error


def parse_pr_ref(value: str) -> int:
    match = re.search(r"(\d+)(?:\D*)\Z", value)
    if not match:
        raise ValueError(f"cannot find a PR number in {value!r}")
    return int(match.group(1))


def overlay_pr_refs() -> list[OverlayMarker]:
    markers = []
    for lineno, line in enumerate(OVERLAY.read_text().splitlines(), start=1):
        match = PR_TRACKER_RE.search(line)
        if not match:
            continue

        rest = match.group("rest")
        package_match = PACKAGE_RE.search(rest)
        markers.append(
            OverlayMarker(
                number=int(match.group("number")),
                targets=tuple(TARGET_RE.findall(rest)),
                package=package_match.group(1) if package_match else None,
                source=f"{OVERLAY.relative_to(REPO)}:{lineno}",
            )
        )

    return markers


def get_pr(number: int) -> PullRequest:
    try:
        data = github_get(f"/pulls/{number}")
    except GitHubHTTPError as error:
        if error.status != 404:
            raise
        issue = github_get(f"/issues/{number}")
        title = issue.get("title", "unknown title")
        if "pull_request" not in issue:
            raise NotPullRequest(f"not a pull request: {title}") from error
        raise

    return PullRequest(
        number=number,
        title=data["title"],
        base_branch=data["base"]["ref"],
        state=data["state"],
        merged_at=data["merged_at"],
        merge_commit_sha=data["merge_commit_sha"],
    )


def next_branches(branch: str) -> list[str]:
    out = []
    for pattern, replacements in NEXT_BRANCH_TABLE:
        if re.match(pattern, branch):
            out.extend(re.sub(pattern, replacement, branch) for replacement in replacements)
    return out


def tracked_branches(base_branch: str) -> list[str]:
    branches = []
    pending = [base_branch]
    seen = set()

    while pending:
        branch = pending.pop(0)
        if branch in seen:
            continue
        branches.append(branch)
        seen.add(branch)
        pending.extend(next_branches(branch))

    return branches


def compare_contains(commit: str, branch: str) -> bool:
    base = urllib.parse.quote(commit, safe="")
    head = urllib.parse.quote(branch, safe="")
    data = github_get(f"/compare/{base}...{head}")
    return data["status"] in {"ahead", "identical"}


def print_pr_header(pr: PullRequest, tracked: list[str]) -> None:
    print(f"PR #{pr.number}: {pr.title}")
    print(f"  base: {pr.base_branch}")
    if pr.merged and pr.merge_commit_sha:
        print(f"  merge commit: {pr.merge_commit_sha}")
    print(f"  pr-tracker branches: {', '.join(tracked)}")


def check_pr(pr: PullRequest, targets: list[str]) -> bool:
    tracked = tracked_branches(pr.base_branch)
    print_pr_header(pr, tracked)

    if not pr.merged:
        if pr.state == "closed":
            print("  FAIL closed without merge")
        else:
            print("  WAIT not merged yet")
        return False

    if not pr.merge_commit_sha:
        print("  UNKNOWN GitHub did not provide a merge commit")
        return False

    ok = True
    for target in targets:
        if target not in tracked:
            print(f"  NOTE {target} is not on pr-tracker's path from {pr.base_branch}")

        try:
            contains = compare_contains(pr.merge_commit_sha, target)
        except GitHubError as error:
            print(f"  ERROR {target}: {error}")
            ok = False
            continue

        if contains:
            print(f"  OK {target} contains the merge commit")
        else:
            print(f"  WAIT {target} does not contain the merge commit")
            ok = False

    return ok


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Check whether nixpkgs PR merge commits have reached channel branches.",
    )
    parser.add_argument(
        "prs",
        metavar="PR",
        nargs="*",
        help="PR number, #123, or a GitHub PR URL",
    )
    parser.add_argument(
        "-t",
        "--target",
        action="append",
        default=[],
        help=f"target branch/channel to check (default: {DEFAULT_TARGET})",
    )
    parser.add_argument(
        "--overlay",
        action="store_true",
        help=f"scan {OVERLAY.relative_to(REPO)} for pr-tracker markers",
    )
    parser.add_argument(
        "--all-tracked",
        action="store_true",
        help="check every branch on pr-tracker's propagation path instead of --target",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    requests = [(parse_pr_ref(value), tuple(args.target)) for value in args.prs]

    if args.overlay:
        overlay_refs = overlay_pr_refs()
        if overlay_refs:
            print("Overlay refs:")
            for marker in overlay_refs:
                targets = args.target or list(marker.targets) or [DEFAULT_TARGET]
                package = f" package={marker.package}" if marker.package else ""
                print(f"  {marker.source}: #{marker.number} target={','.join(targets)}{package}")
                requests.append((marker.number, tuple(targets)))
        else:
            print("Overlay refs: none")

    if not requests:
        print("error: pass a PR number or use --overlay", file=sys.stderr)
        return 2

    all_ok = True
    seen = set()
    for index, (number, request_targets) in enumerate(requests):
        if (number, request_targets) in seen:
            continue
        seen.add((number, request_targets))

        if index:
            print()

        try:
            pr = get_pr(number)
        except GitHubError as error:
            print(f"PR #{number}: ERROR {error}")
            all_ok = False
            continue

        targets = tracked_branches(pr.base_branch) if args.all_tracked else list(request_targets)
        if not targets:
            targets = [DEFAULT_TARGET]

        if not check_pr(pr, targets):
            all_ok = False

    return 0 if all_ok else 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except ValueError as error:
        print(f"error: {error}", file=sys.stderr)
        sys.exit(2)
