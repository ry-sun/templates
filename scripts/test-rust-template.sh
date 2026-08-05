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
github_output="$test_root/github"
invalid_output="$test_root/invalid"
interactive_output="$test_root/interactive"
interactive_log="$test_root/interactive.log"
fake_bin="$test_root/fake-bin"
fake_gh_log="$test_root/gh.log"

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

printf '\n%.0s' 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 | \
    uvx cookiecutter "$repository_root/rust" \
        --accept-hooks yes \
        --output-dir "$interactive_output" \
        >"$interactive_log" 2>&1

grep -Fq 'Publish generated project to GitHub' "$interactive_log"
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

for project in "$bin_project" "$lib_project"; do
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
