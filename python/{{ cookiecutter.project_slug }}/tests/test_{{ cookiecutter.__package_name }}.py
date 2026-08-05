"""Tests for the public library API."""

from {{ cookiecutter.__package_name }} import package_name


def test_package_name_reports_distribution_name() -> None:
    """The package reports the generated distribution name."""
    assert package_name() == "{{ cookiecutter.project_slug }}"
