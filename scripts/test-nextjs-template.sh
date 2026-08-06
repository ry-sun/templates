#!/bin/sh

set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test_root=$(mktemp -d)

cleanup() {
    rm -rf -- "$test_root"
}
trap cleanup EXIT HUP INT TERM

test -f "$repository_root/nextjs/cookiecutter.json"
test -f "$repository_root/nextjs/hooks/pre_gen_project.py"
python3 -m json.tool "$repository_root/nextjs/cookiecutter.json" >/dev/null

invalid_output="$test_root/invalid"
if uvx cookiecutter "$repository_root/nextjs" \
    --no-input \
    --accept-hooks yes \
    --output-dir "$invalid_output" \
    project_slug="Invalid Name" \
    init_git=false \
    github_repository=none \
    >"$test_root/invalid.log" 2>&1; then
    echo "expected invalid project_slug to fail" >&2
    exit 1
fi
grep -Fq "project_slug must start with a lowercase letter" "$test_root/invalid.log"

invalid_publish_output="$test_root/invalid-publish"
if uvx cookiecutter "$repository_root/nextjs" \
    --no-input \
    --accept-hooks yes \
    --output-dir "$invalid_publish_output" \
    project_slug="invalid-publish" \
    init_git=false \
    github_repository=private \
    >"$test_root/invalid-publish.log" 2>&1; then
    echo "expected publishing without Git initialization to fail" >&2
    exit 1
fi
grep -Fq "GitHub publishing requires init_git" "$test_root/invalid-publish.log"

core_output="$test_root/core"
uvx cookiecutter "$repository_root/nextjs" \
    --no-input \
    --accept-hooks yes \
    --output-dir "$core_output" \
    project_name="Example Frontend" \
    project_slug="example-frontend" \
    include_cspell=false \
    include_pre_commit=false \
    include_github_actions=false \
    include_dependabot=false \
    init_git=false \
    github_repository=none
core_project="$core_output/example-frontend"

test -f "$core_project/package.json"
test -f "$core_project/pnpm-lock.yaml"
test -f "$core_project/next-env.d.ts"
test -f "$core_project/src/app/page.tsx"
test -f "$core_project/src/app/page.test.tsx"
test -f "$core_project/vitest.config.mts"

(
    cd "$core_project"
    pnpm install --frozen-lockfile
    pnpm check
    pnpm typecheck
    pnpm test
    pnpm build
)
test -d "$core_project/.next"
