#!/bin/sh

set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test_root=$(mktemp -d)

cleanup() {
    rm -rf -- "$test_root"
}
trap cleanup EXIT HUP INT TERM

test -f "$repository_root/python/cookiecutter.json"
test -f "$repository_root/python/hooks/pre_gen_project.py"
python3 -m json.tool "$repository_root/python/cookiecutter.json" >/dev/null

invalid_output="$test_root/invalid-name"
if uvx cookiecutter "$repository_root/python" \
    --no-input \
    --accept-hooks yes \
    --output-dir "$invalid_output" \
    project_name="Invalid Project" \
    project_slug="class" \
    init_git=false \
    github_repository=none \
    >"$test_root/invalid-name.log" 2>&1; then
    echo "expected Python keyword package name to fail" >&2
    exit 1
fi

grep -Fq "valid non-keyword Python identifier" "$test_root/invalid-name.log"
test ! -e "$invalid_output/class"
