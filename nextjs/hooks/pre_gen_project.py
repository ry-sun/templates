"""Validate values before Cookiecutter renders the Next.js project."""

from __future__ import annotations

import re
import shutil
import subprocess
import sys
from typing import NoReturn

PROJECT_SLUG = {{ cookiecutter.project_slug | tojson }}
DEPLOYMENT_TARGET = {{ cookiecutter.deployment_target | tojson }}
SHADCN_BASE_COLOR = {{ cookiecutter.shadcn_base_color | tojson }}
INIT_GIT = "{{ cookiecutter.init_git }}".lower() == "true"
GITHUB_REPOSITORY = {{ cookiecutter.github_repository | tojson }}
PUSH_TO_GITHUB = GITHUB_REPOSITORY != "none"

PROJECT_SLUG_PATTERN = re.compile(r"^[a-z][a-z0-9_-]*$")
DEPLOYMENT_TARGETS = {"node", "static", "vercel"}
SHADCN_BASE_COLORS = {"neutral", "zinc", "stone", "mauve", "olive", "mist", "taupe"}
GITHUB_REPOSITORIES = {"none", "private", "public"}


def fail(message: str) -> NoReturn:
    """Print a validation error and stop project generation."""
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def node_major() -> int:
    """Return the installed Node.js major version."""
    result = subprocess.run(
        ["node", "--version"],
        check=True,
        capture_output=True,
        text=True,
    )
    match = re.fullmatch(r"v([0-9]+)\.[0-9]+\.[0-9]+\s*", result.stdout)
    if match is None:
        fail("Could not parse 'node --version' output.")
    return int(match.group(1))


if not PROJECT_SLUG_PATTERN.fullmatch(PROJECT_SLUG):
    fail(
        "project_slug must start with a lowercase letter and contain only "
        "lowercase letters, digits, '-' or '_'."
    )

if DEPLOYMENT_TARGET not in DEPLOYMENT_TARGETS:
    fail("deployment_target must be 'node', 'static', or 'vercel'.")

if SHADCN_BASE_COLOR not in SHADCN_BASE_COLORS:
    fail("shadcn_base_color is not supported.")

if GITHUB_REPOSITORY not in GITHUB_REPOSITORIES:
    fail("github_repository must be 'none', 'private', or 'public'.")

if PUSH_TO_GITHUB and not INIT_GIT:
    fail("GitHub publishing requires init_git to be enabled.")

for command in ("node", "pnpm"):
    if shutil.which(command) is None:
        fail(f"Generation requires the {command} command to be installed.")

if node_major() < 24:
    fail("Generation requires Node.js 24 or newer.")

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
