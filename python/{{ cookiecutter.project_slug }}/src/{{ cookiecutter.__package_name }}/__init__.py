"""{{ cookiecutter.project_name }} package."""

{% if cookiecutter.project_type == "lib" %}
def package_name() -> str:
    """Return this distribution's package name."""
    return "{{ cookiecutter.project_slug }}"


__all__ = ["package_name"]
{% else %}
__all__: list[str] = []
{% endif %}
