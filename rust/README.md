# Rust Cookiecutter

This template creates a Rust binary or library as either a single crate or a
Cargo workspace while sharing the same repository conventions.

## Prompts

- Project and Cargo package names
- Binary or library crate
- Optional Cargo workspace with member crates under `crates/`
- Rust edition, minimum supported Rust version, and toolchain channel
- Author and GitHub account
- License and crates.io publishing preference
- CSpell, pre-commit, GitHub Actions, and Dependabot
- Local Git initialization
- GitHub publishing mode: none, private repository, or public repository

The first value of each choice is the default. `project_slug`, the Rust crate
identifier, and `src/main.rs` or `src/lib.rs` are derived from the answers.

## Formatter configuration

The generated `.rustfmt.toml` follows the selected toolchain. Stable projects
receive only the edition, 100-column width, and Unix newline settings. Nightly
projects receive an explicit snapshot of every non-deprecated option reported
by nightly rustfmt, with the selected edition and the template's formatting
preferences applied.

The nightly snapshot is intentionally version-sensitive. When nightly rustfmt
adds, removes, renames, or changes a default setting, update the template and
its `required_version` together.

## Generate

From the repository root:

```sh
uvx cookiecutter ./rust
```

For a non-interactive library:

```sh
uvx cookiecutter ./rust \
  --no-input \
  project_name="Example Library" \
  crate_type=lib \
  init_git=false
```

For a non-interactive workspace with a binary starter crate:

```sh
uvx cookiecutter ./rust \
  --no-input \
  project_name="Example Workspace" \
  use_workspace=true
```

The workspace root owns shared package metadata and lint configuration. Its
initial crate is stored at `crates/<project_slug>/`. Add another direct member
without editing the root manifest:

```sh
cargo new --lib crates/another-crate
```

The post-generation hook removes the unused crate layout and files for
integrations that were not selected.

## Repository initialization

By default, the generated project is initialized on branch `main`, all
generated files are staged, and an `Initial commit` is created using the
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
