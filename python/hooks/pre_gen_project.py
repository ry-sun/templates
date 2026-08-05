"""Validate values before Cookiecutter renders the Python project."""

from __future__ import annotations

import keyword
import re
import shutil
import subprocess
import sys
from typing import NoReturn

PROJECT_SLUG = {{ cookiecutter.project_slug | tojson }}
PACKAGE_NAME = {{ cookiecutter.__package_name | tojson }}
PROJECT_TYPE = {{ cookiecutter.project_type | tojson }}
PYTHON_VERSION = {{ cookiecutter.python_version | tojson }}
INIT_GIT = "{{ cookiecutter.init_git }}".lower() == "true"
GITHUB_REPOSITORY = {{ cookiecutter.github_repository | tojson }}
PUSH_TO_GITHUB = GITHUB_REPOSITORY != "none"

PROJECT_SLUG_PATTERN = re.compile(r"^[a-z][a-z0-9_-]*$")


def fail(message: str) -> NoReturn:
    """Print a validation error and stop project generation."""
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


if not PROJECT_SLUG_PATTERN.fullmatch(PROJECT_SLUG):
    fail(
        "project_slug must start with a lowercase letter and contain only "
        "lowercase letters, digits, '-' or '_'."
    )

if not PACKAGE_NAME.isidentifier() or keyword.iskeyword(PACKAGE_NAME):
    fail("project_slug must produce a valid non-keyword Python identifier.")

if PROJECT_TYPE not in {"cli", "lib"}:
    fail("project_type must be 'cli' or 'lib'.")

if PYTHON_VERSION not in {"3.12", "3.13", "3.14"}:
    fail("python_version must be '3.12', '3.13', or '3.14'.")

if GITHUB_REPOSITORY not in {"none", "private", "public"}:
    fail("github_repository must be 'none', 'private', or 'public'.")

if PUSH_TO_GITHUB and not INIT_GIT:
    fail("GitHub publishing requires init_git to be enabled.")

if shutil.which("uv") is None:
    fail("Generating uv.lock requires the uv command to be installed.")

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
