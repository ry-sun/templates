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

cli_output="$test_root/cli"
lib_output="$test_root/lib"

uvx cookiecutter "$repository_root/python" \
    --no-input \
    --accept-hooks yes \
    --output-dir "$cli_output" \
    init_git=false

uvx cookiecutter "$repository_root/python" \
    --no-input \
    --accept-hooks yes \
    --output-dir "$lib_output" \
    project_name="Example Library" \
    project_slug="example-library" \
    project_type=lib \
    python_version=3.14 \
    license=MIT \
    include_cspell=false \
    include_pre_commit=false \
    include_github_actions=false \
    include_dependabot=false \
    init_git=false \
    github_repository=none

cli_project="$cli_output/my-python-project"
lib_project="$lib_output/example-library"

test -f "$cli_project/src/my_python_project/cli.py"
test -f "$cli_project/src/my_python_project/__main__.py"
test -f "$cli_project/tests/test_cli.py"
test ! -e "$cli_project/tests/test_my_python_project.py"
grep -Fq \
    'my-python-project = "my_python_project.cli:app"' \
    "$cli_project/pyproject.toml"
grep -Fq '"typer>=' "$cli_project/pyproject.toml"

test -f "$lib_project/src/example_library/__init__.py"
test -f "$lib_project/tests/test_example_library.py"
test ! -e "$lib_project/src/example_library/cli.py"
test ! -e "$lib_project/src/example_library/__main__.py"
test ! -e "$lib_project/tests/test_cli.py"
! grep -Fq '[project.scripts]' "$lib_project/pyproject.toml"
! grep -Fq '"typer>=' "$lib_project/pyproject.toml"

test -f "$cli_project/uv.lock"
test -f "$lib_project/uv.lock"
