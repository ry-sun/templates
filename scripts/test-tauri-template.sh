#!/bin/sh

set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test_root=$(mktemp -d)

cleanup() {
    rm -rf -- "$test_root"
}
trap cleanup EXIT HUP INT TERM

test -f "$repository_root/tauri/cookiecutter.json"
test -f "$repository_root/tauri/hooks/pre_gen_project.py"
python3 -m json.tool "$repository_root/tauri/cookiecutter.json" >/dev/null

assert_generation_fails() {
    case_name=$1
    expected_message=$2
    shift 2

    output_directory="$test_root/$case_name"
    log_file="$test_root/$case_name.log"

    if uvx cookiecutter "$repository_root/tauri" \
        --no-input \
        --accept-hooks yes \
        --output-dir "$output_directory" \
        "$@" \
        >"$log_file" 2>&1; then
        printf 'expected %s generation to fail\n' "$case_name" >&2
        exit 1
    fi

    grep -Fq "$expected_message" "$log_file"
}

assert_generation_fails \
    invalid-slug \
    "project_slug must start with a lowercase letter" \
    project_slug="Invalid Name" \
    init_git=false \
    github_repository=none

assert_generation_fails \
    invalid-identifier \
    "bundle_identifier must be a portable reverse-domain identifier" \
    project_slug="valid-project" \
    bundle_identifier="com.ry-sun.app" \
    init_git=false \
    github_repository=none

assert_generation_fails \
    invalid-edition-msrv \
    "Rust edition 2024 requires rust_version 1.85 or newer" \
    project_slug="valid-project" \
    edition=2024 \
    rust_version=1.77.2 \
    init_git=false \
    github_repository=none

assert_generation_fails \
    invalid-publish \
    "GitHub publishing requires init_git to be enabled" \
    project_slug="valid-project" \
    init_git=false \
    github_repository=private

run_pnpm() {
    if command -v pnpm >/dev/null 2>&1; then
        pnpm "$@"
    else
        corepack pnpm "$@"
    fi
}

default_output="$test_root/default"
uvx cookiecutter "$repository_root/tauri" \
    --no-input \
    --accept-hooks yes \
    --output-dir "$default_output" \
    init_git=false \
    github_repository=none
default_project="$default_output/my-tauri-app"

test -f "$default_project/package.json"
test -f "$default_project/pnpm-lock.yaml"
test -f "$default_project/next-env.d.ts"
test -f "$default_project/next.config.ts"
test -f "$default_project/src/app/globals.css"
test -f "$default_project/src/app/layout.tsx"
test -f "$default_project/src/app/page.tsx"
test -f "$default_project/src/app/page.test.tsx"
test -f "$default_project/biome.json"
test -f "$default_project/components.json"
test -f "$default_project/vitest.config.mts"
test ! -d "$default_project/src/app/themes"
test ! -e "$default_project/.gitkeep"

python3 - "$default_project/package.json" <<'PY'
import json
import sys
from pathlib import Path

package = json.loads(Path(sys.argv[1]).read_text())

assert package["dependencies"]["@tauri-apps/api"] == "2.11.1"
assert package["devDependencies"]["@tauri-apps/cli"] == "2.11.4"
assert package["scripts"]["tauri"] == "tauri"
assert "start" not in package["scripts"]
PY

grep -Fq 'output: "export"' "$default_project/next.config.ts"
grep -Fq 'TAURI_DEV_HOST' "$default_project/next.config.ts"
grep -Fq 'invoke<string>("greet"' "$default_project/src/app/page.tsx"

(
    cd "$default_project"
    run_pnpm install --frozen-lockfile
    run_pnpm check
    run_pnpm typecheck
    run_pnpm test
    run_pnpm build
)
test -f "$default_project/out/index.html"
