"""Install and finalize the generated Tauri frontend."""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path


BASE_COLOR = {{ cookiecutter.shadcn_base_color | tojson }}
if shutil.which("pnpm") is not None:
    PNPM_COMMAND = ["pnpm"]
else:
    PNPM_COMMAND = ["corepack", "pnpm"]


def run_command(command: list[str]) -> None:
    """Run a setup command and stop generation if it fails."""
    subprocess.run(command, check=True)


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


select_theme()
install_dependencies()
generate_types()
