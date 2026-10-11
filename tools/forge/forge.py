"""forge: developer tooling for SwarmForge.

    python3 tools/forge/forge.py doctor

`doctor` checks this machine for the problems already met while building
SwarmForge (see docs/failure-lab) and prints how to fix each one.
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from collections.abc import Callable, Sequence
from dataclasses import dataclass
from pathlib import Path

Runner = Callable[[Sequence[str]], subprocess.CompletedProcess]
Which = Callable[[str], "str | None"]

REPO_ROOT = Path(__file__).resolve().parents[2]
FAIL_BELOW_GB = 10
WARN_BELOW_GB = 15


@dataclass
class Result:
    status: str  # "ok", "warn" or "fail"
    check: str
    detail: str
    fix: str = ""


def run(cmd: Sequence[str]) -> subprocess.CompletedProcess:
    """Runs a command and captures its output; never raises."""
    try:
        return subprocess.run(
            list(cmd), capture_output=True, text=True, timeout=60, check=False
        )
    except (OSError, subprocess.TimeoutExpired) as err:
        return subprocess.CompletedProcess(list(cmd), 1, "", str(err))


def check_repo(root: Path) -> Result:
    needed = ("MODULE.bazel", ".bazelversion")
    missing = [name for name in needed if not (root / name).exists()]
    if missing:
        return Result(
            "fail",
            "Repository",
            "missing " + ", ".join(missing),
            "Run forge from inside a SwarmForge checkout.",
        )
    version = (root / ".bazelversion").read_text().strip()
    return Result("ok", "Repository", f"Bazel pinned to {version}")


def check_disk(root: Path, free_bytes: int | None = None) -> Result:
    if free_bytes is None:
        free_bytes = shutil.disk_usage(root).free
    free_gb = free_bytes / 1e9
    detail = f"{free_gb:.1f} GB free"
    fix = (
        "The LLVM toolchain needs about 6 GB (Failure Lab #2). "
        "Try: docker image prune -f, then ./scripts/dev.sh bazel clean"
    )
    if free_gb < FAIL_BELOW_GB:
        return Result("fail", "Disk space", detail, fix)
    if free_gb < WARN_BELOW_GB:
        return Result("warn", "Disk space", detail, fix)
    return Result("ok", "Disk space", detail)


def parse_os_release(text: str) -> dict[str, str]:
    values: dict[str, str] = {}
    for line in text.splitlines():
        key, sep, value = line.partition("=")
        if sep:
            values[key.strip()] = value.strip().strip('"')
    return values


def check_host_os(text: str | None = None) -> Result:
    if text is None:
        path = Path("/etc/os-release")
        text = path.read_text() if path.exists() else ""
    info = parse_os_release(text)
    name = info.get("PRETTY_NAME", "unknown OS")
    if info.get("ID") == "ubuntu" and info.get("VERSION_ID") == "24.04":
        return Result("ok", "Host OS", f"{name} (same as the build image)")
    return Result(
        "warn",
        "Host OS",
        f"{name}: differs from the build image (Ubuntu 24.04)",
        "Build only through ./scripts/dev.sh; host toolchains can break "
        "(Failure Lab #3).",
    )


def check_docker(runner: Runner = run, which: Which = shutil.which) -> Result:
    if which("docker") is None:
        return Result(
            "fail",
            "Docker",
            "not installed",
            "Install Docker Engine: https://docs.docker.com/engine/install/",
        )
    proc = runner(["docker", "info", "--format", "{{.ServerVersion}}"])
    if proc.returncode == 0:
        return Result("ok", "Docker", f"daemon {proc.stdout.strip()} reachable")
    if "permission denied" in proc.stderr.lower():
        return Result(
            "fail",
            "Docker",
            "permission denied",
            "sudo usermod -aG docker $USER, then log out and back in.",
        )
    return Result(
        "fail", "Docker", "daemon not reachable", "sudo systemctl start docker"
    )


def check_plugin(name: str, runner: Runner = run) -> Result:
    proc = runner(["docker", name, "version"])
    if proc.returncode == 0:
        lines = proc.stdout.strip().splitlines()
        return Result("ok", f"docker {name}", lines[0] if lines else "available")
    return Result(
        "fail",
        f"docker {name}",
        "not available",
        f"Install Docker's docker-{name}-plugin package.",
    )


def check_dev_image(runner: Runner = run) -> Result:
    proc = runner(["docker", "image", "inspect", "swarmforge-dev"])
    if proc.returncode == 0:
        return Result("ok", "Build image", "swarmforge-dev is present")
    return Result(
        "warn",
        "Build image",
        "swarmforge-dev not built yet",
        "./scripts/dev.sh true  (builds it, about 2 minutes)",
    )


def check_gh(runner: Runner = run, which: Which = shutil.which) -> Result:
    if which("gh") is None:
        return Result(
            "warn",
            "GitHub CLI",
            "not installed",
            "Needed for the PR workflow: https://cli.github.com",
        )
    proc = runner(["gh", "auth", "status"])
    if proc.returncode == 0:
        return Result("ok", "GitHub CLI", "logged in")
    return Result("warn", "GitHub CLI", "not logged in", "gh auth login")


def doctor(root: Path = REPO_ROOT) -> int:
    results = [
        check_repo(root),
        check_host_os(),
        check_disk(root),
        check_docker(),
        check_plugin("buildx"),
        check_plugin("compose"),
        check_dev_image(),
        check_gh(),
    ]
    for result in results:
        print(f"[{result.status.upper():<4}] {result.check:<14} {result.detail}")
        if result.fix:
            print(f"{'':7}fix: {result.fix}")
    failed = sum(result.status == "fail" for result in results)
    warned = sum(result.status == "warn" for result in results)
    print(f"\n{failed} failed, {warned} warnings")
    return 1 if failed else 0


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="forge", description="SwarmForge developer tooling"
    )
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("doctor", help="check this machine and explain fixes")
    args = parser.parse_args(argv)
    if args.command == "doctor":
        return doctor()
    return 2


if __name__ == "__main__":
    sys.exit(main())
