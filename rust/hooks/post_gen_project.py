"""Remove generated files disabled by the selected Cookiecutter options."""

from __future__ import annotations

import os
import shutil
import subprocess
from pathlib import Path

INCLUDE_CSPELL = "{{ cookiecutter.include_cspell }}" == "True"
INCLUDE_PRE_COMMIT = "{{ cookiecutter.include_pre_commit }}" == "True"
INCLUDE_GITHUB_ACTIONS = "{{ cookiecutter.include_github_actions }}" == "True"
INCLUDE_DEPENDABOT = "{{ cookiecutter.include_dependabot }}" == "True"
LICENSE = "{{ cookiecutter.license }}"
INIT_GIT = "{{ cookiecutter.init_git }}".lower() == "true"
GITHUB_REPOSITORY = {{ cookiecutter.github_repository | tojson }}
PUSH_TO_GITHUB = GITHUB_REPOSITORY != "none"
GITHUB_USERNAME = {{ cookiecutter.github_username | tojson }}
PROJECT_SLUG = {{ cookiecutter.project_slug | tojson }}
AUTHOR_NAME = {{ cookiecutter.author_name | tojson }}
AUTHOR_EMAIL = {{ cookiecutter.author_email | tojson }}


def remove(path: str) -> None:
    """Remove a generated file or directory if it exists."""
    target = Path(path)
    if target.is_dir():
        shutil.rmtree(target)
    elif target.exists():
        target.unlink()


def run_command(command: list[str], *, env: dict[str, str] | None = None) -> None:
    """Run a repository setup command and stop generation if it fails."""
    subprocess.run(command, check=True, env=env)


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

if INIT_GIT:
    initialize_git_repository()

if PUSH_TO_GITHUB:
    publish_to_github()
