"""{{ cookiecutter.project_name }} package."""


def package_name() -> str:
    """Return this distribution's package name."""
    return "{{ cookiecutter.project_slug }}"


__all__ = ["package_name"]
