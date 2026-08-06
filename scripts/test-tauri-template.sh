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
