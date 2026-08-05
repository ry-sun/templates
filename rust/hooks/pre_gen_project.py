"""Validate values before Cookiecutter renders the Rust project."""

from __future__ import annotations

import re
import shutil
import subprocess
import sys

PROJECT_SLUG = "{{ cookiecutter.project_slug }}"
RUST_VERSION = "{{ cookiecutter.rust_version }}"
INIT_GIT = "{{ cookiecutter.init_git }}".lower() == "true"
GITHUB_REPOSITORY = "{{ cookiecutter.github_repository }}"
PUSH_TO_GITHUB = GITHUB_REPOSITORY != "none"

PROJECT_SLUG_PATTERN = re.compile(r"^[a-z][a-z0-9_-]*$")
RUST_VERSION_PATTERN = re.compile(r"^[0-9]+\.[0-9]+(?:\.[0-9]+)?$")


def fail(message: str) -> None:
    """Print a validation error and stop project generation."""
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


if not PROJECT_SLUG_PATTERN.fullmatch(PROJECT_SLUG):
    fail(
        "project_slug must start with a lowercase letter and contain only "
        "lowercase letters, digits, '-' or '_'."
    )

if not RUST_VERSION_PATTERN.fullmatch(RUST_VERSION):
    fail("rust_version must look like '1.85' or '1.85.0'.")

if GITHUB_REPOSITORY not in {"none", "private", "public"}:
    fail("github_repository must be 'none', 'private', or 'public'.")

if PUSH_TO_GITHUB and not INIT_GIT:
    fail("GitHub publishing requires init_git to be enabled.")

if INIT_GIT and shutil.which("git") is None:
    fail("init_git requires the git command to be installed.")

if PUSH_TO_GITHUB:
    if shutil.which("gh") is None:
        fail("GitHub publishing requires the gh command to be installed.")

    try:
        subprocess.run(
            ["gh", "auth", "status"],
            check=True,
            capture_output=True,
            text=True,
        )
    except subprocess.CalledProcessError:
        fail("GitHub CLI is not authenticated; run 'gh auth login' and retry.")
