# {{ cookiecutter.project_name }}

{{ cookiecutter.description }}

## Development

```sh
cargo fmt --all -- --check
cargo clippy --all-targets --all-features -- -D warnings
cargo test --all-features
```

{% if cookiecutter.include_pre_commit -%}
Install the repository hooks with:

```sh
pre-commit install --install-hooks
pre-commit install --hook-type pre-push
```
{% endif -%}

## License

{% if cookiecutter.license == "MIT OR Apache-2.0" -%}
Licensed under either the Apache License, Version 2.0 or the MIT License, at
your option.
{% elif cookiecutter.license == "None" -%}
No license is granted for this project.
{% else -%}
Licensed under the {{ cookiecutter.license }} license.
{% endif -%}
