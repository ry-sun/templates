# {{ cookiecutter.project_name }}

{{ cookiecutter.description }}

## Development

```sh
uv sync --locked
uv run ruff format --check .
uv run ruff check .
uv run basedpyright
uv run pytest
uv build
```

{% if cookiecutter.project_type == "cli" %}
Run the command-line application:

```sh
uv run {{ cookiecutter.project_slug }} --help
uv run python -m {{ cookiecutter.__package_name }} --help
```
{% else %}
Import the library:

```python
from {{ cookiecutter.__package_name }} import package_name

print(package_name())
```
{% endif %}

## License

{% if cookiecutter.license == "MIT OR Apache-2.0" %}
Licensed under either the Apache License, Version 2.0 or the MIT License, at
your option.
{% elif cookiecutter.license == "None" %}
No license is granted for this project.
{% else %}
Licensed under the {{ cookiecutter.license }} license.
{% endif %}
