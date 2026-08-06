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
