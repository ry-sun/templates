"""Command-line interface for {{ cookiecutter.project_name }}."""

import typer

app = typer.Typer(no_args_is_help=False)


@app.command()
def main() -> None:
    """Run {{ cookiecutter.project_name }}."""
    typer.echo("Hello from {{ cookiecutter.project_name }}!")
