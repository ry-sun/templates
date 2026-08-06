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
    github_repository=none
core_project="$core_output/example-frontend"

test -f "$core_project/package.json"
test -f "$core_project/pnpm-lock.yaml"
test -f "$core_project/next-env.d.ts"
test -f "$core_project/src/app/page.tsx"
test -f "$core_project/src/app/page.test.tsx"
test -f "$core_project/vitest.config.mts"
test -f "$core_project/components.json"
test -f "$core_project/src/lib/utils.ts"
test -f "$core_project/.editorconfig"
test -f "$core_project/.gitattributes"
test -f "$core_project/.gitignore"
test -f "$core_project/.cspell.json"
test -f "$core_project/.cspell.ignore-words.txt"
test -f "$core_project/.pre-commit-config.yaml"
test -f "$core_project/.github/workflows/check.yml"
test -f "$core_project/.github/dependabot.yml"
test -f "$core_project/LICENSE-MIT"
test -f "$core_project/LICENSE-APACHE"
test ! -d "$core_project/src/components/ui"
test ! -d "$core_project/src/app/themes"
test ! -e "$core_project/vercel.json"
grep -Fq '"baseColor": "neutral"' "$core_project/components.json"
grep -Fq 'oklch(0.145 0 0)' "$core_project/src/app/globals.css"

(
    cd "$core_project"
    pnpm install --frozen-lockfile
    pnpm check
    pnpm typecheck
    pnpm test
    pnpm build
)
test -d "$core_project/.next"

zinc_output="$test_root/zinc"
uvx cookiecutter "$repository_root/nextjs" \
    --no-input \
    --accept-hooks yes \
    --output-dir "$zinc_output" \
    project_slug="zinc-frontend" \
    shadcn_base_color=zinc \
    deployment_target=static \
    enable_react_compiler=true \
    include_cspell=false \
    include_pre_commit=false \
    include_github_actions=false \
    include_dependabot=false \
    init_git=false \
    github_repository=none
zinc_project="$zinc_output/zinc-frontend"

grep -Fq '"baseColor": "zinc"' "$zinc_project/components.json"
grep -Fq 'oklch(0.141 0.005 285.823)' "$zinc_project/src/app/globals.css"
test ! -d "$zinc_project/src/app/themes"
! cmp -s "$core_project/src/app/globals.css" "$zinc_project/src/app/globals.css"
test ! -e "$zinc_project/vercel.json"
grep -Fq 'reactCompiler: true' "$zinc_project/next.config.ts"
grep -Fq 'output: "export"' "$zinc_project/next.config.ts"

python3 - "$core_project/package.json" "$zinc_project/package.json" <<'PY'
import json
import sys
from pathlib import Path

node_package = json.loads(Path(sys.argv[1]).read_text())
static_package = json.loads(Path(sys.argv[2]).read_text())
assert node_package["scripts"]["start"] == "next start"
assert "start" not in static_package["scripts"]
assert "babel-plugin-react-compiler" not in node_package["devDependencies"]
assert static_package["devDependencies"]["babel-plugin-react-compiler"] == "1.0.0"
PY

(
    cd "$zinc_project"
    pnpm install --frozen-lockfile
    pnpm check
    pnpm typecheck
    pnpm test
    pnpm build
)
test -f "$zinc_project/out/index.html"
test ! -e "$zinc_project/.cspell.json"
test ! -e "$zinc_project/.cspell.ignore-words.txt"
test ! -e "$zinc_project/.pre-commit-config.yaml"
test ! -e "$zinc_project/.github"
test -f "$zinc_project/LICENSE-MIT"
test -f "$zinc_project/LICENSE-APACHE"
test ! -e "$zinc_project/.git"

vercel_output="$test_root/vercel"
FAKE_GH_LOG="$fake_gh_log" PATH="$fake_bin:$PATH" \
uvx cookiecutter "$repository_root/nextjs" \
    --no-input \
    --accept-hooks yes \
    --output-dir "$vercel_output" \
    project_name="Published Next.js App" \
    project_slug="published-nextjs-app" \
    deployment_target=vercel \
    init_git=true \
    github_repository=private
vercel_project="$vercel_output/published-nextjs-app"

test -f "$vercel_project/vercel.json"
python3 -m json.tool "$vercel_project/vercel.json" >/dev/null
! grep -Fq 'reactCompiler: true' "$vercel_project/next.config.ts"
! grep -Fq 'output: "export"' "$vercel_project/next.config.ts"
(
    cd "$vercel_project"
    pnpm install --frozen-lockfile
    pnpm check
    pnpm typecheck
    pnpm test
    pnpm build
)
test -d "$vercel_project/.next"

for project in "$core_project" "$vercel_project"; do
    test -d "$project/.git"
    test "$(git -C "$project" branch --show-current)" = "main"
    test "$(git -C "$project" rev-list --count HEAD)" -eq 1
    test "$(git -C "$project" log -1 --format=%s)" = "Initial commit"
    test "$(git -C "$project" log -1 --format=%ae)" = "ruiyangsun02@gmail.com"
    test -z "$(git -C "$project" status --porcelain)"
done

grep -Fxq "auth status" "$fake_gh_log"
grep -Fxq \
    "repo create ry-sun/published-nextjs-app --private --source=. --remote=origin --push" \
    "$fake_gh_log"

python3 -m json.tool "$core_project/.cspell.json" >/dev/null
uvx pre-commit validate-config "$core_project/.pre-commit-config.yaml"
uv run --with pyyaml python - \
    "$core_project/.pre-commit-config.yaml" \
    "$core_project/.github/workflows/check.yml" \
    "$core_project/.github/dependabot.yml" <<'PY'
import sys
from pathlib import Path

import yaml

for path in sys.argv[1:]:
    with Path(path).open(encoding="utf-8") as stream:
        assert isinstance(yaml.safe_load(stream), dict)
PY
