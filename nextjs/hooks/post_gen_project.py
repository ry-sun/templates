"""Finalize the generated Next.js project."""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path


BASE_COLOR = "{{ cookiecutter.shadcn_base_color }}"
DEPLOYMENT_TARGET = "{{ cookiecutter.deployment_target }}"


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


def remove(path: str) -> None:
    """Remove a rendered file or directory when its variant is disabled."""
    target = Path(path)
    if target.is_dir():
        shutil.rmtree(target)
    elif target.exists():
        target.unlink()


select_theme()
if DEPLOYMENT_TARGET != "vercel":
    remove("vercel.json")
install_dependencies()
generate_types()
