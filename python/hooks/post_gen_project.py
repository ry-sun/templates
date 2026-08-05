"""Finalize the generated Python project."""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

PROJECT_TYPE = {{ cookiecutter.project_type | tojson }}
PACKAGE_NAME = {{ cookiecutter.__package_name | tojson }}


def remove(path: str) -> None:
    """Remove a generated file or directory if it exists."""
    target = Path(path)
    if target.is_dir():
        shutil.rmtree(target)
    elif target.exists():
        target.unlink()


def run_command(command: list[str], *, env: dict[str, str] | None = None) -> None:
    """Run a project setup command and stop generation if it fails."""
    subprocess.run(command, check=True, env=env)


def lock_dependencies() -> None:
    """Resolve and write the generated project's uv lockfile."""
    run_command(["uv", "lock"])


if PROJECT_TYPE == "cli":
    remove(f"tests/test_{PACKAGE_NAME}.py")
else:
    remove(f"src/{PACKAGE_NAME}/cli.py")
    remove(f"src/{PACKAGE_NAME}/__main__.py")
    remove("tests/test_cli.py")

lock_dependencies()
