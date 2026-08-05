#!/bin/sh

set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test_root=$(mktemp -d)

cleanup() {
    rm -rf -- "$test_root"
}
trap cleanup EXIT HUP INT TERM

bin_output="$test_root/bin"
lib_output="$test_root/lib"
workspace_bin_output="$test_root/workspace-bin"
workspace_lib_output="$test_root/workspace-lib"
github_output="$test_root/github"
invalid_output="$test_root/invalid"
interactive_output="$test_root/interactive"
interactive_log="$test_root/interactive.log"
fake_bin="$test_root/fake-bin"
fake_gh_log="$test_root/gh.log"
workspace_lockfile_template='rust/{{ cookiecutter.project_slug }}/Cargo.lock.template'

test -f "$repository_root/$workspace_lockfile_template"
! git -C "$repository_root" check-ignore -q "$workspace_lockfile_template"

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

printf '\n%.0s' 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 | \
    uvx cookiecutter "$repository_root/rust" \
        --accept-hooks yes \
        --output-dir "$interactive_output" \
        >"$interactive_log" 2>&1

grep -Fq 'Publish generated project to GitHub' "$interactive_log"
grep -Fq 'Generate a Cargo workspace with crates under crates/' "$interactive_log"
! grep -Fq 'Create and push the repository to GitHub immediately' "$interactive_log"
! grep -Fq 'GitHub repository visibility' "$interactive_log"

uvx cookiecutter "$repository_root/rust" \
    --no-input \
    --accept-hooks yes \
    --output-dir "$bin_output"

uvx cookiecutter "$repository_root/rust" \
    --no-input \
    --accept-hooks yes \
    --output-dir "$lib_output" \
    project_name="Example Library" \
    project_slug="example-library" \
    crate_type="lib" \
    license="MIT" \
    include_cspell=false \
    include_pre_commit=false \
    include_github_actions=false \
    include_dependabot=false \
    init_git=false \
    github_repository=none

uvx cookiecutter "$repository_root/rust" \
    --no-input \
    --accept-hooks yes \
    --output-dir "$workspace_bin_output" \
    project_name="Example Workspace" \
    project_slug="example-workspace" \
    use_workspace=true

uvx cookiecutter "$repository_root/rust" \
    --no-input \
    --accept-hooks yes \
    --output-dir "$workspace_lib_output" \
    project_name="Example Workspace Library" \
    project_slug="example-workspace-library" \
    crate_type=lib \
    use_workspace=true \
    edition=2021 \
    license=MIT \
    include_cspell=false \
    include_pre_commit=false \
    include_github_actions=false \
    include_dependabot=false \
    init_git=false \
    github_repository=none

FAKE_GH_LOG="$fake_gh_log" PATH="$fake_bin:$PATH" \
    uvx cookiecutter "$repository_root/rust" \
    --no-input \
    --accept-hooks yes \
    --output-dir "$github_output" \
    project_name="Published Project" \
    project_slug="published-project" \
    init_git=true \
    github_repository=private

if uvx cookiecutter "$repository_root/rust" \
    --no-input \
    --accept-hooks yes \
    --output-dir "$invalid_output" \
    project_name="Invalid Project" \
    project_slug="invalid-project" \
    init_git=false \
    github_repository=private \
    >"$test_root/invalid.log" 2>&1; then
    echo "expected publishing without Git initialization to fail" >&2
    exit 1
fi

bin_project="$bin_output/my-rust-project"
lib_project="$lib_output/example-library"
workspace_bin_project="$workspace_bin_output/example-workspace"
workspace_lib_project="$workspace_lib_output/example-workspace-library"
github_project="$github_output/published-project"

test -d "$bin_project/.git"
test "$(git -C "$bin_project" branch --show-current)" = "main"
test "$(git -C "$bin_project" rev-list --count HEAD)" -eq 1
test "$(git -C "$bin_project" log -1 --format=%s)" = "Initial commit"
test -z "$(git -C "$bin_project" status --porcelain)"

test -f "$bin_project/src/main.rs"
test ! -e "$bin_project/src/lib.rs"
test -f "$bin_project/.github/workflows/check.yml"
test -f "$bin_project/.github/dependabot.yml"
test -f "$bin_project/.cspell.json"
test -f "$bin_project/.pre-commit-config.yaml"
test -f "$bin_project/LICENSE-MIT"
test -f "$bin_project/LICENSE-APACHE"
! grep -q '^Cargo.lock$' "$bin_project/.gitignore"

test -f "$lib_project/src/lib.rs"
test ! -e "$lib_project/src/main.rs"
test ! -e "$lib_project/.github"
test ! -e "$lib_project/.cspell.json"
test ! -e "$lib_project/.pre-commit-config.yaml"
test -f "$lib_project/LICENSE-MIT"
test ! -e "$lib_project/LICENSE-APACHE"
grep -q '^Cargo.lock$' "$lib_project/.gitignore"
test ! -e "$lib_project/.git"

test -d "$workspace_bin_project/.git"
test "$(git -C "$workspace_bin_project" branch --show-current)" = "main"
test "$(git -C "$workspace_bin_project" rev-list --count HEAD)" -eq 1
test "$(git -C "$workspace_bin_project" log -1 --format=%s)" = "Initial commit"
test -z "$(git -C "$workspace_bin_project" status --porcelain)"
git -C "$workspace_bin_project" ls-files --error-unmatch Cargo.lock >/dev/null
! git -C "$workspace_bin_project" check-ignore -q Cargo.lock
test -f "$workspace_bin_project/Cargo.toml"
test -f "$workspace_bin_project/Cargo.lock"
test ! -e "$workspace_bin_project/src"
test -f "$workspace_bin_project/crates/example-workspace/Cargo.toml"
test -f "$workspace_bin_project/crates/example-workspace/src/main.rs"
test ! -e "$workspace_bin_project/crates/example-workspace/src/lib.rs"

test ! -e "$workspace_lib_project/.git"
test -f "$workspace_lib_project/Cargo.toml"
test -f "$workspace_lib_project/Cargo.lock"
test ! -e "$workspace_lib_project/src"
test -f "$workspace_lib_project/crates/example-workspace-library/Cargo.toml"
test -f "$workspace_lib_project/crates/example-workspace-library/src/lib.rs"
test ! -e "$workspace_lib_project/crates/example-workspace-library/src/main.rs"
! grep -q '^Cargo.lock$' "$workspace_lib_project/.gitignore"

test -d "$github_project/.git"
test "$(git -C "$github_project" branch --show-current)" = "main"
test "$(git -C "$github_project" rev-list --count HEAD)" -eq 1
test -z "$(git -C "$github_project" status --porcelain)"
grep -Fxq 'auth status' "$fake_gh_log"
grep -Fxq \
    'repo create ry-sun/published-project --private --source=. --remote=origin --push' \
    "$fake_gh_log"

grep -Fq 'GitHub publishing requires init_git' "$test_root/invalid.log"
test ! -e "$invalid_output/invalid-project"

python3 -m json.tool "$repository_root/rust/cookiecutter.json" >/dev/null
python3 -m json.tool "$bin_project/.cspell.json" >/dev/null
uvx pre-commit validate-config "$bin_project/.pre-commit-config.yaml"

for workspace_case in \
    "$workspace_bin_project|example-workspace|2024|3" \
    "$workspace_lib_project|example-workspace-library|2021|2"; do
    workspace_project=${workspace_case%%|*}
    workspace_fields=${workspace_case#*|}
    workspace_package=${workspace_fields%%|*}
    workspace_fields=${workspace_fields#*|}
    workspace_edition=${workspace_fields%%|*}
    workspace_resolver=${workspace_fields#*|}
    workspace_metadata="$test_root/$workspace_package-metadata.json"

    cargo metadata \
        --manifest-path "$workspace_project/Cargo.toml" \
        --format-version 1 \
        --no-deps \
        >"$workspace_metadata"

    python3 - \
        "$workspace_project" \
        "$workspace_package" \
        "$workspace_edition" \
        "$workspace_resolver" \
        "$workspace_metadata" <<'PY'
import json
import sys
import tomllib
from pathlib import Path

workspace_root = Path(sys.argv[1]).resolve()
package_name = sys.argv[2]
edition = sys.argv[3]
resolver = sys.argv[4]
metadata_path = Path(sys.argv[5])

with (workspace_root / "Cargo.toml").open("rb") as manifest_file:
    root_manifest = tomllib.load(manifest_file)

assert "package" not in root_manifest
assert root_manifest["workspace"]["members"] == ["crates/*"]
assert root_manifest["workspace"]["resolver"] == resolver
assert root_manifest["workspace"]["package"]["edition"] == edition
assert root_manifest["workspace"]["lints"]["rust"]["unsafe_code"] == "forbid"
assert root_manifest["workspace"]["lints"]["clippy"]["pedantic"] == "warn"

crate_manifest_path = workspace_root / "crates" / package_name / "Cargo.toml"
with crate_manifest_path.open("rb") as manifest_file:
    crate_manifest = tomllib.load(manifest_file)

package = crate_manifest["package"]
assert package["name"] == package_name
for field in (
    "version",
    "authors",
    "edition",
    "rust-version",
    "description",
    "readme",
    "repository",
    "license",
    "publish",
):
    assert package[field] == {"workspace": True}
assert crate_manifest["lints"] == {"workspace": True}

metadata = json.loads(metadata_path.read_text())
assert Path(metadata["workspace_root"]).resolve() == workspace_root
assert metadata["workspace_members"] == [metadata["packages"][0]["id"]]
assert len(metadata["packages"]) == 1
assert metadata["packages"][0]["name"] == package_name
assert Path(metadata["packages"][0]["manifest_path"]).resolve() == crate_manifest_path
PY
done

for project in \
    "$bin_project" \
    "$lib_project" \
    "$workspace_bin_project" \
    "$workspace_lib_project"; do
    cargo metadata \
        --manifest-path "$project/Cargo.toml" \
        --format-version 1 \
        --no-deps \
        >/dev/null
    cargo fmt --manifest-path "$project/Cargo.toml" --all -- --check
    cargo clippy \
        --manifest-path "$project/Cargo.toml" \
        --all-targets \
        --all-features \
        -- \
        -D warnings
    cargo test --manifest-path "$project/Cargo.toml" --all-features
done

test -z "$(git -C "$workspace_bin_project" status --porcelain)"
