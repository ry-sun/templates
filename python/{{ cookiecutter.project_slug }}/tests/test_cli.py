"""Tests for the command-line interface."""

from typer.testing import CliRunner

from {{ cookiecutter.__package_name }}.cli import app

runner = CliRunner()


def test_cli_reports_project_name() -> None:
    """The root command prints the generated project name."""
    result = runner.invoke(app)

    assert result.exit_code == 0
    assert result.output == "Hello from {{ cookiecutter.project_name }}!\n"
