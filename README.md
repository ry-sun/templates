# Project Templates

Personal project templates powered by
[Cookiecutter](https://cookiecutter.readthedocs.io/).

## Available templates

| Template | Description |
| --- | --- |
| `rust` | Rust binary, library, or Cargo workspace with shared repository tooling |

## Usage

Generate a Rust project from this checkout:

```sh
uvx cookiecutter ./rust
```

After this repository is published to GitHub, the same template can be used with:

```sh
uvx cookiecutter gh:ry-sun/templates --directory rust
```

Cookiecutter runs the template's hooks by default for a trusted local checkout.
The Rust template hooks validate answers, remove disabled files, initialize Git
when selected, and can create and push a GitHub repository through an
authenticated GitHub CLI session.

## Development

Run the template smoke tests:

```sh
./scripts/test-rust-template.sh
```

The tests generate single-crate and workspace binary and library variants in
temporary directories, check their conditional files and Git state, record
GitHub CLI calls with a local fake, and run Rust formatting, linting, and test
commands. They never create a real GitHub repository.
