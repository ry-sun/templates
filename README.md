# Project Templates

Personal project templates powered by
[Cookiecutter](https://cookiecutter.readthedocs.io/).

## Available templates

| Template | Description |
| --- | --- |
| `nextjs` | Next.js frontend with pnpm, Biome, Tailwind, Vitest, and shadcn/ui |
| `python` | Typer CLI or reusable library with uv-based tooling |
| `rust` | Rust binary, library, or Cargo workspace with shared repository tooling |

## Usage

Generate a project from this checkout:

```sh
uvx cookiecutter ./nextjs
uvx cookiecutter ./python
uvx cookiecutter ./rust
```

After this repository is published to GitHub, the templates can be used with:

```sh
uvx cookiecutter gh:ry-sun/templates --directory nextjs
uvx cookiecutter gh:ry-sun/templates --directory python
uvx cookiecutter gh:ry-sun/templates --directory rust
```

Cookiecutter runs the template's hooks by default for a trusted local checkout.
The hooks validate answers, remove disabled files, initialize Git when selected,
and can create and push a GitHub repository through an authenticated GitHub CLI
session. The Python template resolves `uv.lock`, while the Next.js template
resolves `pnpm-lock.yaml` and generates route types before Git initialization.

## Development

Run the template smoke tests:

```sh
./scripts/test-nextjs-template.sh
./scripts/test-python-template.sh
./scripts/test-rust-template.sh
```

The tests generate Next.js Node, static-export, and Vercel projects; Python CLI
and library projects; and Rust single-crate and workspace binary and library
projects in temporary directories. They check conditional files and Git state,
record GitHub CLI calls with a local fake, and run each language's formatting,
linting, type-checking, testing, and build commands. They never create a real
GitHub repository or Vercel project.
