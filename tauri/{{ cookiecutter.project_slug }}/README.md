# {{ cookiecutter.project_name }}

{{ cookiecutter.description }}

This project uses Tauri v2 with a Rust backend and a statically exported Next.js
frontend. The starter page invokes a typed Rust greeting command.

## Selected targets

Platform scope: `{{ cookiecutter.platform_scope }}`.

{% if cookiecutter.platform_scope in ["desktop", "both"] -%}
{% if cookiecutter.desktop_targets == "all" -%}
Desktop targets: macOS, Windows, and Linux.
{% elif cookiecutter.desktop_targets == "macos" -%}
Desktop target: macOS.
{% elif cookiecutter.desktop_targets == "windows" -%}
Desktop target: Windows.
{% else -%}
Desktop target: Linux.
{% endif %}
{% endif %}
{% if cookiecutter.platform_scope in ["mobile", "both"] -%}
{% if cookiecutter.mobile_targets == "both" -%}
Mobile targets: Android and iOS.
{% elif cookiecutter.mobile_targets == "android" -%}
Mobile target: Android.
{% else -%}
Mobile target: iOS.
{% endif %}
{% endif %}

## Prerequisites

- Node.js 24 or newer
- pnpm or Corepack
- Rust and Cargo through rustup
- Native Tauri dependencies for the selected targets
{% if cookiecutter.platform_scope in ["mobile", "both"] -%}
{% if cookiecutter.mobile_targets in ["both", "android"] -%}
- Android SDK and NDK for Android development
{% endif %}
{% endif %}
{% if cookiecutter.platform_scope in ["mobile", "both"] -%}
{% if cookiecutter.mobile_targets in ["both", "ios"] -%}
- macOS and Xcode for iOS development
{% endif %}
{% endif %}

## Develop and check

```sh
pnpm dev
pnpm check
pnpm typecheck
pnpm test
pnpm build
pnpm tauri dev
pnpm tauri build
```

`pnpm dev` runs the static Next.js frontend by itself. Use `pnpm tauri dev` for
the integrated native application.

{% if cookiecutter.platform_scope in ["mobile", "both"] -%}
## Mobile initialization

Native mobile projects are intentionally initialized after Cookiecutter
generation, on a host with the required SDK.

{% if cookiecutter.mobile_targets in ["both", "android"] -%}
### Android

```sh
pnpm tauri android init
pnpm tauri android dev
pnpm tauri android build
```
{% endif %}
{% if cookiecutter.mobile_targets in ["both", "ios"] -%}
### iOS

```sh
pnpm tauri ios init
pnpm tauri ios dev
pnpm tauri ios build
```
{% endif %}
{% endif %}

## Continuous integration

{% if cookiecutter.include_github_actions -%}
The generated workflow uses the `{{ cookiecutter.ci_scope }}` scope.
{% if cookiecutter.ci_scope == "checks" -%}
It runs frontend formatting, type checking, tests, and static export plus Rust
formatting, Clippy, and tests. It does not build platform packages.
{% else -%}
It runs all fast checks and builds the selected native targets. The native jobs
produce unsigned or development builds; signing, store submission, and release
publication require separate user-owned credentials and configuration.
{% endif %}
{% else -%}
GitHub Actions was not included in this project.
{% endif %}

## Repository lifecycle

{% if cookiecutter.init_git -%}
Generation created branch `main` with one `Initial commit`.
{% else -%}
Generation did not initialize a Git repository.
{% endif %}
{% if cookiecutter.github_repository != "none" -%}
The project was published as a {{ cookiecutter.github_repository }} repository at
`{{ cookiecutter.github_username }}/{{ cookiecutter.project_slug }}`.
{% endif %}
