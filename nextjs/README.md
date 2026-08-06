# Next.js Cookiecutter

This template creates a frontend-focused Next.js application using the App
Router, React, TypeScript, a `src/` layout, Tailwind CSS, Biome, pnpm, Vitest,
React Testing Library, and configuration-only shadcn/ui.

## Prerequisites

- Node.js 24 or newer
- pnpm, either as a direct command or through Corepack
- Cookiecutter, invoked through `uvx` in the examples below
- Git when repository initialization is enabled
- An authenticated GitHub CLI when GitHub publishing is selected

If Node.js provides Corepack but the `pnpm` command is not enabled, generation
uses `corepack pnpm` automatically. Enable the shorter command afterward with:

```sh
corepack enable pnpm
```

## Generate

From the repository root:

```sh
uvx cookiecutter ./nextjs
```

From GitHub:

```sh
uvx cookiecutter gh:ry-sun/templates --directory nextjs
```

For a non-interactive static-export project with React Compiler enabled:

```sh
uvx cookiecutter ./nextjs \
  --no-input \
  project_name="Example Frontend" \
  deployment_target=static \
  enable_react_compiler=true \
  init_git=false
```

## Prompts

| Prompt | Default | Choices or purpose |
| --- | --- | --- |
| `project_name` | `My Next.js App` | Human-readable project name |
| `project_slug` | derived | Repository and package name |
| `description` | `A Next.js frontend application.` | Package and page description |
| `author_name` | `Ryan Sun` | Package and Git author name |
| `author_email` | `ruiyangsun02@gmail.com` | Package and Git author email |
| `github_username` | `ry-sun` | Publishing owner and dependency reviewer |
| `license` | `MIT OR Apache-2.0` | Dual, MIT, Apache-2.0, or none |
| `copyright_year` | `2026` | License copyright year |
| `enable_react_compiler` | `false` | Add React Compiler configuration |
| `shadcn_base_color` | `neutral` | Neutral, Zinc, Stone, Mauve, Olive, Mist, or Taupe |
| `deployment_target` | `node` | Node server, static export, or Vercel |
| `include_cspell` | `true` | Include CSpell configuration |
| `include_pre_commit` | `true` | Include pre-commit hooks |
| `include_github_actions` | `true` | Include generated-project CI |
| `include_dependabot` | `true` | Include Dependabot configuration |
| `init_git` | `true` | Create a clean `main` initial commit |
| `github_repository` | `none` | Do not publish, or publish privately/publicly |

The first value of each choice is the default.

## Generated project

Generated projects provide these commands:

```sh
pnpm dev
pnpm build
pnpm start       # Node and Vercel targets only
pnpm check
pnpm format
pnpm typecheck
pnpm test
```

The Node target uses the normal Next.js production server. Static export sets
`output: "export"` and writes deployable files to `out/`; features that require
a Next.js server runtime are unavailable. The Vercel target adds `vercel.json`
but does not provision or deploy a remote project.

shadcn/ui is initialized for the `new-york` style, Radix foundation, CSS
variables, and the generated `src/` aliases, but no UI component is installed.
Add one when needed:

```sh
pnpm dlx shadcn@latest add button
```

## Repository initialization

The post-generation hook first selects the requested theme and removes disabled
files. It then installs dependencies, creates `pnpm-lock.yaml`, and generates
Next.js types before any Git or GitHub side effect.

With `init_git=true`, it creates branch `main` and an `Initial commit` using the
prompted author identity without changing Git configuration. Selecting a
private or public GitHub repository requires Git initialization and uses
`gh repo create` to create and push `<github_username>/<project_slug>`.

GitHub repository creation is external and cannot be rolled back by
Cookiecutter. If creation succeeds but pushing fails, remove or repair the
remote repository manually before retrying.
