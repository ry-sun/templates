"""Validate values before Cookiecutter renders the Tauri project."""

from __future__ import annotations

import re
import shutil
import subprocess
import sys
from typing import NoReturn


PROJECT_SLUG = {{ cookiecutter.project_slug | tojson }}
BUNDLE_IDENTIFIER = {{ cookiecutter.bundle_identifier | tojson }}
PLATFORM_SCOPE = {{ cookiecutter.platform_scope | tojson }}
DESKTOP_TARGETS = {{ cookiecutter.desktop_targets | tojson }}
MOBILE_TARGETS = {{ cookiecutter.mobile_targets | tojson }}
CI_SCOPE = {{ cookiecutter.ci_scope | tojson }}
EDITION = {{ cookiecutter.edition | tojson }}
RUST_VERSION = {{ cookiecutter.rust_version | tojson }}
TOOLCHAIN = {{ cookiecutter.toolchain | tojson }}
SHADCN_BASE_COLOR = {{ cookiecutter.shadcn_base_color | tojson }}
INIT_GIT = "{{ cookiecutter.init_git }}".lower() == "true"
GITHUB_REPOSITORY = {{ cookiecutter.github_repository | tojson }}
PUSH_TO_GITHUB = GITHUB_REPOSITORY != "none"

PROJECT_SLUG_PATTERN = re.compile(r"^[a-z][a-z0-9_-]*$")
IDENTIFIER_SEGMENT_PATTERN = re.compile(r"^[a-z][a-z0-9]*$")
RUST_VERSION_PATTERN = re.compile(r"^[0-9]+\.[0-9]+(?:\.[0-9]+)?$")
PLATFORM_SCOPES = {"desktop", "mobile", "both"}
DESKTOP_TARGET_CHOICES = {"all", "macos", "windows", "linux"}
MOBILE_TARGET_CHOICES = {"both", "android", "ios"}
CI_SCOPES = {"checks", "full-builds"}
EDITIONS = {"2024", "2021"}
TOOLCHAINS = {"stable", "nightly"}
SHADCN_BASE_COLORS = {"neutral", "zinc", "stone", "mauve", "olive", "mist", "taupe"}
GITHUB_REPOSITORIES = {"none", "private", "public"}


def fail(message: str) -> NoReturn:
    """Print a validation error and stop project generation."""
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def version_tuple(version: str) -> tuple[int, int, int]:
    """Normalize a Rust version string for numeric comparison."""
    components = [int(component) for component in version.split(".")]
    components.extend([0] * (3 - len(components)))
    return tuple(components[:3])


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

identifier_segments = BUNDLE_IDENTIFIER.split(".")
if len(identifier_segments) < 2 or any(
    IDENTIFIER_SEGMENT_PATTERN.fullmatch(segment) is None
    for segment in identifier_segments
):
    fail(
        "bundle_identifier must be a portable reverse-domain identifier whose "
        "segments start with a lowercase letter and contain only lowercase "
        "letters or digits."
    )

if PLATFORM_SCOPE not in PLATFORM_SCOPES:
    fail("platform_scope must be 'desktop', 'mobile', or 'both'.")

if DESKTOP_TARGETS not in DESKTOP_TARGET_CHOICES:
    fail("desktop_targets must be 'all', 'macos', 'windows', or 'linux'.")

if MOBILE_TARGETS not in MOBILE_TARGET_CHOICES:
    fail("mobile_targets must be 'both', 'android', or 'ios'.")

if CI_SCOPE not in CI_SCOPES:
    fail("ci_scope must be 'checks' or 'full-builds'.")

if EDITION not in EDITIONS:
    fail("edition must be '2024' or '2021'.")

if TOOLCHAIN not in TOOLCHAINS:
    fail("toolchain must be 'stable' or 'nightly'.")

if SHADCN_BASE_COLOR not in SHADCN_BASE_COLORS:
    fail("shadcn_base_color is not supported.")

if GITHUB_REPOSITORY not in GITHUB_REPOSITORIES:
    fail("github_repository must be 'none', 'private', or 'public'.")

if not RUST_VERSION_PATTERN.fullmatch(RUST_VERSION):
    fail("rust_version must look like '1.97' or '1.97.0'.")

if version_tuple(RUST_VERSION) < (1, 77, 2):
    fail("Tauri requires rust_version 1.77.2 or newer.")

if EDITION == "2024" and version_tuple(RUST_VERSION) < (1, 85, 0):
    fail("Rust edition 2024 requires rust_version 1.85 or newer.")

if PUSH_TO_GITHUB and not INIT_GIT:
    fail("GitHub publishing requires init_git to be enabled.")

if shutil.which("node") is None:
    fail("Generation requires the node command to be installed.")

if shutil.which("pnpm") is None and shutil.which("corepack") is None:
    fail("Generation requires pnpm or Corepack to be installed.")

if node_major() < 24:
    fail("Generation requires Node.js 24 or newer.")

if shutil.which("cargo") is None or shutil.which("rustc") is None:
    fail("Generation requires Cargo and rustc to be installed.")

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
