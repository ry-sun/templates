"""Finalize the generated Next.js project."""

from __future__ import annotations

import subprocess
import shutil
from pathlib import Path


BASE_COLOR = "{{ cookiecutter.shadcn_base_color }}"


def run_command(command: list[str], *, env: dict[str, str] | None = None) -> None:
    """Run a setup command and stop generation if it fails."""
    subprocess.run(command, check=True, env=env)


def install_dependencies() -> None:
    """Install dependencies and create the generated pnpm lockfile."""
    run_command(["pnpm", "install"])


def generate_types() -> None:
    """Generate Next.js declarations and route types."""
    run_command(["pnpm", "next", "typegen"])


def select_theme() -> None:
    """Install the requested shadcn base color and remove staging themes."""
    app_directory = Path("src/app")
    themes_directory = app_directory / "themes"
    (themes_directory / f"{BASE_COLOR}.css").replace(app_directory / "globals.css")
    shutil.rmtree(themes_directory)


select_theme()
install_dependencies()
generate_types()
