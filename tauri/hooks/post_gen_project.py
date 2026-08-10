"""Finalize the generated Tauri project."""

from __future__ import annotations

import os
import shutil
import subprocess
from pathlib import Path


BASE_COLOR = {{ cookiecutter.shadcn_base_color | tojson }}
INCLUDE_CSPELL = "{{ cookiecutter.include_cspell }}".lower() == "true"
INCLUDE_PRE_COMMIT = "{{ cookiecutter.include_pre_commit }}".lower() == "true"
INCLUDE_GITHUB_ACTIONS = "{{ cookiecutter.include_github_actions }}".lower() == "true"
INCLUDE_DEPENDABOT = "{{ cookiecutter.include_dependabot }}".lower() == "true"
LICENSE = {{ cookiecutter.license | tojson }}
INIT_GIT = "{{ cookiecutter.init_git }}".lower() == "true"
GITHUB_REPOSITORY = {{ cookiecutter.github_repository | tojson }}
PUSH_TO_GITHUB = GITHUB_REPOSITORY != "none"
GITHUB_USERNAME = {{ cookiecutter.github_username | tojson }}
PROJECT_SLUG = {{ cookiecutter.project_slug | tojson }}
AUTHOR_NAME = {{ cookiecutter.author_name | tojson }}
AUTHOR_EMAIL = {{ cookiecutter.author_email | tojson }}
if shutil.which("pnpm") is not None:
    PNPM_COMMAND = ["pnpm"]
else:
    PNPM_COMMAND = ["corepack", "pnpm"]


def run_command(command: list[str], *, env: dict[str, str] | None = None) -> None:
    """Run a setup command and stop generation if it fails."""
    subprocess.run(command, check=True, env=env)


def remove(path: str) -> None:
    """Remove a generated file or directory when its option is disabled."""
    target = Path(path)
    if target.is_dir():
        shutil.rmtree(target)
    elif target.exists():
        target.unlink()


def select_theme() -> None:
    """Install the requested shadcn base color and remove staging themes."""
    app_directory = Path("src/app")
    themes_directory = app_directory / "themes"
    (themes_directory / f"{BASE_COLOR}.css").replace(app_directory / "globals.css")
    shutil.rmtree(themes_directory)


def install_dependencies() -> None:
    """Install frontend dependencies and create the pnpm lockfile."""
    run_command([*PNPM_COMMAND, "install"])


def generate_types() -> None:
    """Generate Next.js declarations and route types."""
    run_command([*PNPM_COMMAND, "next", "typegen"])


def generate_cargo_lockfile() -> None:
    """Resolve Rust dependencies without compiling the application."""
    run_command(
        ["cargo", "generate-lockfile", "--manifest-path", "src-tauri/Cargo.toml"]
    )


def initialize_git_repository() -> None:
    """Create the main branch and commit all generated project files."""
    run_command(["git", "init", "--initial-branch=main"])
    run_command(["git", "add", "--all"])

    commit_environment = os.environ.copy()
    commit_environment.update(
        {
            "GIT_AUTHOR_NAME": AUTHOR_NAME,
            "GIT_AUTHOR_EMAIL": AUTHOR_EMAIL,
            "GIT_COMMITTER_NAME": AUTHOR_NAME,
            "GIT_COMMITTER_EMAIL": AUTHOR_EMAIL,
        }
    )
    run_command(
        ["git", "commit", "-m", "Initial commit"],
        env=commit_environment,
    )


def publish_to_github() -> None:
    """Create the requested GitHub repository and push the initial commit."""
    run_command(
        [
            "gh",
            "repo",
            "create",
            f"{GITHUB_USERNAME}/{PROJECT_SLUG}",
            f"--{GITHUB_REPOSITORY}",
            "--source=.",
            "--remote=origin",
            "--push",
        ]
    )


select_theme()

if not INCLUDE_CSPELL:
    remove(".cspell.json")
    remove(".cspell.ignore-words.txt")

if not INCLUDE_PRE_COMMIT:
    remove(".pre-commit-config.yaml")

if not INCLUDE_GITHUB_ACTIONS:
    remove(".github/workflows")

if not INCLUDE_DEPENDABOT:
    remove(".github/dependabot.yml")

if LICENSE == "MIT":
    remove("LICENSE-APACHE")
elif LICENSE == "Apache-2.0":
    remove("LICENSE-MIT")
elif LICENSE == "None":
    remove("LICENSE-APACHE")
    remove("LICENSE-MIT")

github_directory = Path(".github")
if github_directory.exists() and not any(github_directory.iterdir()):
    github_directory.rmdir()

install_dependencies()
generate_types()
generate_cargo_lockfile()

if INIT_GIT:
    initialize_git_repository()

if PUSH_TO_GITHUB:
    publish_to_github()
