# Python Cookiecutter

This template creates either an installable Typer command-line application or
a reusable Python library. Both variants use uv, Hatchling, a `src/` layout,
Ruff, pytest, and strict basedpyright.

## Prompts

- Project, distribution, and import package names
- Typer CLI or reusable library
- Minimum Python version: 3.12, 3.13, or 3.14
- Author and GitHub account
- License
- CSpell, pre-commit, GitHub Actions, and Dependabot
- Local Git initialization
- GitHub publishing mode: none, private repository, or public repository

The first value of each choice is the default. The import package name and Ruff
target version are derived from the selected answers.

## Generate

From the repository root:

```sh
uvx cookiecutter ./python
```

After this repository is published to GitHub:

```sh
uvx cookiecutter gh:ry-sun/templates --directory python
```

For a non-interactive library:

```sh
uvx cookiecutter ./python \
  --no-input \
  project_name="Example Library" \
  project_type=lib \
  init_git=false
```

The post-generation hook removes files for integrations and the project variant
that were not selected. It then runs `uv lock`, which may access the configured
package index. A lock failure stops generation before any Git or GitHub change.

## Development

Generated projects use these checks:

```sh
uv lock --check
uv sync --locked
uv run ruff format --check .
uv run ruff check .
uv run basedpyright
uv run pytest
uv build
```

The CLI variant provides both the generated console command and
`python -m <package_name>`. The library variant has no runtime dependencies.

## Repository initialization

By default, the generated project is initialized on branch `main`, all files
including `uv.lock` are staged, and an `Initial commit` is created using the
prompted author name and email. This does not modify global or local Git
configuration. Set `init_git=false` to leave the project as a plain directory.

When `github_repository` is `private` or `public`, the template also requires
an installed and authenticated `gh` command. It creates
`<github_username>/<project_slug>` with the selected visibility, configures
`origin`, and pushes the initial commit. Choose `none` to skip GitHub
publishing. Publishing requires Git initialization.

GitHub repository creation is external and cannot be rolled back by
Cookiecutter. If GitHub creates the repository but the subsequent push fails,
remove or repair that remote repository manually before retrying.
