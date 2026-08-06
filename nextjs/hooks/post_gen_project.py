"""Finalize the generated Next.js project."""

from __future__ import annotations

import subprocess


def run_command(command: list[str], *, env: dict[str, str] | None = None) -> None:
    """Run a setup command and stop generation if it fails."""
    subprocess.run(command, check=True, env=env)


def install_dependencies() -> None:
    """Install dependencies and create the generated pnpm lockfile."""
    run_command(["pnpm", "install"])


def generate_types() -> None:
    """Generate Next.js declarations and route types."""
    run_command(["pnpm", "next", "typegen"])


install_dependencies()
generate_types()
