# {{ cookiecutter.project_name }}

{{ cookiecutter.description }}

## Development

Install dependencies and run the local development server:

```sh
pnpm install --frozen-lockfile
pnpm dev
```

Run the project checks with:

```sh
pnpm check
pnpm typecheck
pnpm test
pnpm build
```

## Deployment

{% if cookiecutter.deployment_target == "node" -%}
This project targets a provider-neutral Node.js server. Build it with
`pnpm build`, then run the production server with `pnpm start`.
{% elif cookiecutter.deployment_target == "static" -%}
This project uses Next.js static export. `pnpm build` writes deployable files to
`out/`; serve that directory from any static host. Features that require a
Next.js server runtime are unavailable in this deployment mode.
{% else -%}
This project is configured for Vercel through `vercel.json`. Connect the
repository to a Vercel project or deploy it with the Vercel CLI; generation does
not provision or deploy a remote project.
{% endif %}
