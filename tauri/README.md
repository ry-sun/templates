# Tauri Cookiecutter

This template creates a Tauri v2 application with a standard Rust backend under
`src-tauri/` and a statically exported Next.js App Router frontend. The frontend
uses TypeScript, Tailwind CSS, Biome, pnpm, Vitest, React Testing Library, and
configuration-only shadcn/ui.

## Prerequisites

- Node.js 24 or newer
- pnpm, either directly or through Corepack
- Rust and Cargo through rustup
- Cookiecutter, invoked through `uvx` below
- Native Tauri development dependencies for each selected target
- Git when repository initialization is enabled
- An authenticated GitHub CLI when GitHub publishing is selected

Follow the official Tauri prerequisite guide for Linux, macOS, Windows,
Android, and iOS dependencies. Android requires the Android SDK and NDK. iOS
development requires macOS and Xcode. Cookiecutter generation does not require
the mobile SDKs because native mobile projects are initialized afterward.

## Generate

From the repository root:

```sh
uvx cookiecutter ./tauri
```

From GitHub:

```sh
uvx cookiecutter gh:ry-sun/templates --directory tauri
```

For a non-interactive desktop project with fast CI checks:

```sh
uvx cookiecutter ./tauri \
  --no-input \
  project_name="Example Desktop App" \
  bundle_identifier="com.example.desktopapp" \
  platform_scope=desktop \
  desktop_targets=all \
  ci_scope=checks \
  init_git=false
```

For a combined macOS and Android project with native-build CI:

```sh
uvx cookiecutter ./tauri \
  --no-input \
  project_name="Example Cross Platform App" \
  bundle_identifier="com.example.crossplatformapp" \
  platform_scope=both \
  desktop_targets=macos \
  mobile_targets=android \
  ci_scope=full-builds
```

## Prompts

| Prompt | Default | Choices or purpose |
| --- | --- | --- |
| `project_name` | `My Tauri App` | Human-readable application name |
| `project_slug` | derived | Repository, pnpm package, and Cargo package name |
| `description` | `A Tauri desktop and mobile application.` | Package description |
| `author_name` | `Ryan Sun` | Package and Git author name |
| `author_email` | `ruiyangsun02@gmail.com` | Package and Git author email |
| `github_username` | `ry-sun` | GitHub owner and dependency reviewer |
| `bundle_identifier` | derived | Portable reverse-domain application identifier |
| `platform_scope` | `desktop` | Desktop, mobile, or both |
| `desktop_targets` | `all` | macOS, Windows, Linux, or all three |
| `mobile_targets` | `both` | Android, iOS, or both |
| `ci_scope` | `checks` | Fast checks or selected native builds |
| `edition` | `2024` | Rust 2024 or 2021 edition |
| `rust_version` | `1.97` | Minimum supported Rust version |
| `toolchain` | `stable` | Stable or nightly Rust toolchain |
| `license` | `MIT OR Apache-2.0` | Dual, MIT, Apache-2.0, or none |
| `copyright_year` | `2026` | License copyright year |
| `enable_react_compiler` | `false` | Add React Compiler configuration |
| `shadcn_base_color` | `neutral` | Neutral, Zinc, Stone, Mauve, Olive, Mist, or Taupe |
| `include_cspell` | `true` | Include CSpell configuration |
| `include_pre_commit` | `true` | Include pre-commit hooks |
| `include_github_actions` | `true` | Include generated-project CI |
| `include_dependabot` | `true` | Include npm, Cargo, and Actions updates |
| `init_git` | `true` | Create a clean `main` initial commit |
| `github_repository` | `none` | Do not publish, or publish privately/publicly |

Cookiecutter displays both target prompts. `desktop_targets` is ignored for a
mobile-only project, and `mobile_targets` is ignored for a desktop-only project.
The first value of every choice is the default.

## Generated project

The frontend always uses Next.js static export because Tauri hosts static web
assets rather than a Node server. The starter page invokes a typed `greet`
command in Rust and includes frontend and Rust tests for the bridge.

Generated projects provide:

```sh
pnpm dev
pnpm build
pnpm check
pnpm format
pnpm typecheck
pnpm test
pnpm tauri dev
pnpm tauri build
```

For selected mobile platforms, initialize native projects after generation:

```sh
pnpm tauri android init
pnpm tauri ios init
```

The generated README includes only commands relevant to its effective targets.

## GitHub Actions

The default `checks` workflow runs frontend formatting, type checks, tests, and
static export plus Rust formatting, Clippy, and tests. `full-builds` adds native
jobs only for the selected desktop and mobile targets. Mobile jobs initialize
their native project in the ephemeral CI checkout.

Full-build workflows validate unsigned or development builds. They do not
create releases, submit to stores, or contain code-signing credentials.

## Repository initialization

Generation selects the requested theme, removes disabled files, installs pnpm
dependencies, generates Next.js types, and resolves both lockfiles before Git
or GitHub side effects.

With `init_git=true`, it creates branch `main` and an `Initial commit` using the
prompted author identity without changing Git configuration. Selecting a
private or public GitHub repository requires Git initialization and uses
`gh repo create` to create and push `<github_username>/<project_slug>`.

GitHub repository creation is external and cannot be rolled back by
Cookiecutter. If creation succeeds but pushing fails, remove or repair the
remote repository manually before retrying.
