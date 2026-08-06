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

test -f "$repository_root/tauri/cookiecutter.json"
test -f "$repository_root/tauri/hooks/pre_gen_project.py"
test -f "$repository_root/tauri/README.md"
python3 -m json.tool "$repository_root/tauri/cookiecutter.json" >/dev/null

grep -Fq '| `tauri` |' "$repository_root/README.md"
grep -Fq 'uvx cookiecutter ./tauri' "$repository_root/README.md"
grep -Fq './scripts/test-tauri-template.sh' "$repository_root/README.md"
grep -Fq '`platform_scope`' "$repository_root/tauri/README.md"
grep -Fq '`desktop_targets`' "$repository_root/tauri/README.md"
grep -Fq '`mobile_targets`' "$repository_root/tauri/README.md"
grep -Fq '`ci_scope`' "$repository_root/tauri/README.md"

uv run --with pyyaml python - "$repository_root/.github/workflows/test.yml" <<'PY'
import sys
from pathlib import Path

import yaml

with Path(sys.argv[1]).open(encoding="utf-8") as stream:
    workflow = yaml.safe_load(stream)

assert any(
    step.get("run") == "./scripts/test-tauri-template.sh"
    for step in workflow["jobs"]["tauri"]["steps"]
)
PY

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

test -f "$default_project/src-tauri/Cargo.toml"
test -f "$default_project/src-tauri/build.rs"
test -f "$default_project/src-tauri/tauri.conf.json"
test -f "$default_project/src-tauri/capabilities/default.json"
test -f "$default_project/src-tauri/src/lib.rs"
test -f "$default_project/src-tauri/src/main.rs"
test -f "$default_project/src-tauri/icons/icon.icns"
test -f "$default_project/src-tauri/icons/icon.ico"
test -f "$default_project/rust-toolchain.toml"
test -f "$default_project/.rustfmt.toml"
test -f "$default_project/.clippy.toml"
test -f "$default_project/src-tauri/Cargo.lock"
test -f "$default_project/.editorconfig"
test -f "$default_project/.gitattributes"
test -f "$default_project/.node-version"
test -f "$default_project/.cspell.json"
test -f "$default_project/.cspell.ignore-words.txt"
test -f "$default_project/.pre-commit-config.yaml"
test -f "$default_project/LICENSE-MIT"
test -f "$default_project/LICENSE-APACHE"
test -f "$default_project/.github/workflows/check.yml"
test -f "$default_project/.github/dependabot.yml"
test -f "$default_project/README.md"
grep -Fq 'macOS, Windows, and Linux' "$default_project/README.md"
! grep -Fq 'pnpm tauri android init' "$default_project/README.md"
! grep -Fq 'pnpm tauri ios init' "$default_project/README.md"

python3 - \
    "$default_project/src-tauri/Cargo.toml" \
    "$default_project/src-tauri/tauri.conf.json" \
    "$default_project/src-tauri/capabilities/default.json" <<'PY'
import json
import sys
import tomllib
from pathlib import Path

with Path(sys.argv[1]).open("rb") as manifest_file:
    manifest = tomllib.load(manifest_file)

package = manifest["package"]
assert package["name"] == "my-tauri-app"
assert package["edition"] == "2024"
assert package["rust-version"] == "1.97"
assert package["publish"] is False
assert manifest["dependencies"]["tauri"]["version"] == "=2.11.5"
assert manifest["build-dependencies"]["tauri-build"]["version"] == "=2.6.3"

config = json.loads(Path(sys.argv[2]).read_text())
assert config["productName"] == "My Tauri App"
assert config["identifier"] == "com.rysun.mytauriapp"
assert config["build"] == {
    "beforeBuildCommand": "pnpm build",
    "beforeDevCommand": "pnpm dev",
    "devUrl": "http://localhost:3000",
    "frontendDist": "../out",
}

capability = json.loads(Path(sys.argv[3]).read_text())
assert capability["identifier"] == "default"
assert capability["windows"] == ["main"]
assert capability["permissions"] == ["core:default"]
PY

grep -Fq 'fn greeting(name: &str) -> String' "$default_project/src-tauri/src/lib.rs"
grep -Fq '#[tauri::command]' "$default_project/src-tauri/src/lib.rs"

stripped_output="$test_root/stripped"
uvx cookiecutter "$repository_root/tauri" \
    --no-input \
    --accept-hooks yes \
    --output-dir "$stripped_output" \
    project_name="Mobile Tauri App" \
    project_slug="mobile-tauri-app" \
    bundle_identifier="com.example.mobiletauriapp" \
    platform_scope=mobile \
    mobile_targets=both \
    edition=2021 \
    rust_version=1.77.2 \
    shadcn_base_color=zinc \
    license=MIT \
    include_cspell=false \
    include_pre_commit=false \
    include_github_actions=false \
    include_dependabot=false \
    init_git=false \
    github_repository=none
stripped_project="$stripped_output/mobile-tauri-app"

test -f "$stripped_project/pnpm-lock.yaml"
test -f "$stripped_project/src-tauri/Cargo.lock"
test -f "$stripped_project/LICENSE-MIT"
test ! -e "$stripped_project/LICENSE-APACHE"
test ! -e "$stripped_project/.cspell.json"
test ! -e "$stripped_project/.cspell.ignore-words.txt"
test ! -e "$stripped_project/.pre-commit-config.yaml"
test ! -e "$stripped_project/.github"
test ! -e "$stripped_project/.git"
grep -Fq 'oklch(0.141 0.005 285.823)' "$stripped_project/src/app/globals.css"
grep -Fq 'pnpm tauri android init' "$stripped_project/README.md"
grep -Fq 'pnpm tauri ios init' "$stripped_project/README.md"
! grep -Fq 'Windows and Linux' "$stripped_project/README.md"
grep -Fq 'edition = "2021"' "$stripped_project/src-tauri/Cargo.toml"
grep -Fq 'rust-version = "1.77.2"' "$stripped_project/src-tauri/Cargo.toml"

published_output="$test_root/published"
FAKE_GH_LOG="$fake_gh_log" PATH="$fake_bin:$PATH" \
uvx cookiecutter "$repository_root/tauri" \
    --no-input \
    --accept-hooks yes \
    --output-dir "$published_output" \
    project_name="Published Tauri App" \
    project_slug="published-tauri-app" \
    bundle_identifier="com.example.publishedtauriapp" \
    platform_scope=both \
    desktop_targets=macos \
    mobile_targets=android \
    ci_scope=full-builds \
    toolchain=nightly \
    enable_react_compiler=true \
    init_git=true \
    github_repository=private
published_project="$published_output/published-tauri-app"

test -d "$published_project/.git"
test "$(git -C "$published_project" branch --show-current)" = "main"
test "$(git -C "$published_project" rev-list --count HEAD)" -eq 1
test "$(git -C "$published_project" log -1 --format=%s)" = "Initial commit"
test "$(git -C "$published_project" log -1 --format=%ae)" = "ruiyangsun02@gmail.com"
test -z "$(git -C "$published_project" status --porcelain)"
git -C "$published_project" ls-files --error-unmatch pnpm-lock.yaml >/dev/null
git -C "$published_project" ls-files --error-unmatch src-tauri/Cargo.lock >/dev/null
grep -Fxq "auth status" "$fake_gh_log"
grep -Fxq \
    "repo create ry-sun/published-tauri-app --private --source=. --remote=origin --push" \
    "$fake_gh_log"
grep -Fq 'macOS' "$published_project/README.md"
grep -Fq 'Android' "$published_project/README.md"
grep -Fq 'full-builds' "$published_project/README.md"
! grep -Fq 'pnpm tauri ios init' "$published_project/README.md"
grep -Fq 'reactCompiler: true' "$published_project/next.config.ts"
grep -Fq 'channel = "nightly"' "$published_project/rust-toolchain.toml"
grep -Fq 'unstable_features = true' "$published_project/.rustfmt.toml"

uv run --with pyyaml python - \
    "$default_project/.github/workflows/check.yml" \
    "$default_project/.github/dependabot.yml" \
    "$published_project/.github/workflows/check.yml" <<'PY'
import sys
from pathlib import Path

import yaml


def load_yaml(path: str) -> dict:
    with Path(path).open(encoding="utf-8") as stream:
        value = yaml.safe_load(stream)
    assert isinstance(value, dict)
    return value


default_workflow = load_yaml(sys.argv[1])
assert set(default_workflow["jobs"]) == {"frontend", "rust"}
assert any(
    step.get("run") == "pnpm install --frozen-lockfile"
    for step in default_workflow["jobs"]["frontend"]["steps"]
)
assert any(
    "cargo clippy --manifest-path src-tauri/Cargo.toml" in step.get("run", "")
    for step in default_workflow["jobs"]["rust"]["steps"]
)

dependabot = load_yaml(sys.argv[2])
ecosystems = {
    (update["package-ecosystem"], update["directory"])
    for update in dependabot["updates"]
}
assert ecosystems == {
    ("cargo", "/src-tauri"),
    ("github-actions", "/"),
    ("npm", "/"),
}

full_workflow = load_yaml(sys.argv[3])
assert set(full_workflow["jobs"]) == {
    "build-android",
    "build-macos",
    "frontend",
    "rust",
}
android_steps = full_workflow["jobs"]["build-android"]["steps"]
assert any(step.get("run") == "pnpm tauri android init --ci" for step in android_steps)
assert any(
    step.get("run") == "pnpm tauri android build --debug --apk --ci"
    for step in android_steps
)
workflow_text = Path(sys.argv[3]).read_text()
assert "tauri-action" not in workflow_text
assert "release" not in workflow_text.lower()
PY

python3 -m json.tool "$default_project/.cspell.json" >/dev/null
uvx pre-commit validate-config "$default_project/.pre-commit-config.yaml"

(
    cd "$default_project"
    run_pnpm install --frozen-lockfile
    run_pnpm check
    run_pnpm typecheck
    run_pnpm test
    run_pnpm build
    cargo metadata --manifest-path src-tauri/Cargo.toml --format-version 1 --no-deps >/dev/null
    cargo fmt --manifest-path src-tauri/Cargo.toml --all -- --check
    cargo clippy \
        --manifest-path src-tauri/Cargo.toml \
        --all-targets \
        --all-features \
        -- \
        -D warnings
    cargo test --manifest-path src-tauri/Cargo.toml --all-features
    run_pnpm tauri build --no-bundle
)
test -f "$default_project/out/index.html"
