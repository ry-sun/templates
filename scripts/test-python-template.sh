#!/bin/sh

set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test_root=$(mktemp -d)
fake_bin="$test_root/fake-bin"
fake_gh_log="$test_root/gh.log"

cleanup() {
    rm -rf -- "$test_root"
}
trap cleanup EXIT HUP INT TERM

mkdir -p "$fake_bin"

cat >"$fake_bin/gh" <<'EOF'
#!/bin/sh

set -eu

printf '%s\n' "$*" >>"$FAKE_GH_LOG"

case "$*" in
    "auth status" | "repo create "*)
        exit 0
        ;;
    *)
        printf 'unexpected gh invocation: %s\n' "$*" >&2
        exit 2
        ;;
esac
EOF
chmod +x "$fake_bin/gh"

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
    --output-dir "$cli_output"

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

github_output="$test_root/github"
FAKE_GH_LOG="$fake_gh_log" PATH="$fake_bin:$PATH" \
    uvx cookiecutter "$repository_root/python" \
    --no-input \
    --accept-hooks yes \
    --output-dir "$github_output" \
    project_name="Published Python Project" \
    project_slug="published-python-project" \
    init_git=true \
    github_repository=private

invalid_publish_output="$test_root/invalid-publish"
if uvx cookiecutter "$repository_root/python" \
    --no-input \
    --accept-hooks yes \
    --output-dir "$invalid_publish_output" \
    project_name="Invalid Publish" \
    project_slug="invalid-publish" \
    init_git=false \
    github_repository=private \
    >"$test_root/invalid-publish.log" 2>&1; then
    echo "expected publishing without Git initialization to fail" >&2
    exit 1
fi

cli_project="$cli_output/my-python-project"
lib_project="$lib_output/example-library"
github_project="$github_output/published-python-project"

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

test -f "$cli_project/.editorconfig"
test -f "$cli_project/.gitattributes"
test -f "$cli_project/.gitignore"
test -f "$cli_project/.cspell.json"
test -f "$cli_project/.pre-commit-config.yaml"
test -f "$cli_project/.github/workflows/check.yml"
test -f "$cli_project/.github/dependabot.yml"
test -f "$cli_project/LICENSE-MIT"
test -f "$cli_project/LICENSE-APACHE"

test ! -e "$lib_project/.cspell.json"
test ! -e "$lib_project/.pre-commit-config.yaml"
test ! -e "$lib_project/.github"
test -f "$lib_project/LICENSE-MIT"
test ! -e "$lib_project/LICENSE-APACHE"

test -d "$cli_project/.git"
test "$(git -C "$cli_project" branch --show-current)" = "main"
test "$(git -C "$cli_project" rev-list --count HEAD)" -eq 1
test "$(git -C "$cli_project" log -1 --format=%s)" = "Initial commit"
test "$(git -C "$cli_project" log -1 --format=%ae)" = "ruiyangsun02@gmail.com"
test -z "$(git -C "$cli_project" status --porcelain)"

test ! -e "$lib_project/.git"

test -d "$github_project/.git"
test "$(git -C "$github_project" branch --show-current)" = "main"
test "$(git -C "$github_project" rev-list --count HEAD)" -eq 1
test -z "$(git -C "$github_project" status --porcelain)"
grep -Fxq "auth status" "$fake_gh_log"
grep -Fxq \
    "repo create ry-sun/published-python-project --private --source=. --remote=origin --push" \
    "$fake_gh_log"

grep -Fq "GitHub publishing requires init_git" "$test_root/invalid-publish.log"
test ! -e "$invalid_publish_output/invalid-publish"

python3 -m json.tool "$cli_project/.cspell.json" >/dev/null

for project in "$cli_project" "$lib_project"; do
    python3 -c \
        'import pathlib, sys, tomllib; tomllib.loads(pathlib.Path(sys.argv[1]).read_text())' \
        "$project/pyproject.toml"

    (
        cd "$project"
        uv lock --check
        uv sync --locked
        uv run ruff format --check .
        uv run ruff check .
        uv run basedpyright
        uv run pytest
    )
done

uvx pre-commit validate-config "$cli_project/.pre-commit-config.yaml"

uv run --with pyyaml python - \
    "$cli_project/.github/workflows/check.yml" \
    "$cli_project/.github/dependabot.yml" <<'PY'
from __future__ import annotations

import sys
from pathlib import Path

import yaml

for path in sys.argv[1:]:
    with Path(path).open(encoding="utf-8") as stream:
        assert isinstance(yaml.safe_load(stream), dict)
PY

test -z "$(git -C "$cli_project" status --porcelain)"

uv run --project "$cli_project" my-python-project --help >/dev/null
uv run --project "$cli_project" python -m my_python_project --help >/dev/null
test "$(
    uv run --project "$lib_project" \
        python -c 'from example_library import package_name; print(package_name())'
)" = "example-library"

uv build "$cli_project"
uv build "$lib_project"

cli_wheel=$(find "$cli_project/dist" -name '*.whl' -print -quit)
lib_wheel=$(find "$lib_project/dist" -name '*.whl' -print -quit)
test -n "$cli_wheel"
test -n "$lib_wheel"
unzip -l "$cli_wheel" | grep -Fq "my_python_project/__init__.py"
unzip -l "$cli_wheel" | grep -Fq "my_python_project/py.typed"
unzip -l "$lib_wheel" | grep -Fq "example_library/__init__.py"
unzip -l "$lib_wheel" | grep -Fq "example_library/py.typed"
