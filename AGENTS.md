# Repository Guidelines

## Project Structure & Module Organization

This repository contains project templates rather than a directly runnable
application. Each top-level template directory contains its prompt contract,
generation hooks, README, and generated project tree. Root-level `scripts/`
render representative variants into temporary directories and validate the
results; CI invokes them from `.github/workflows/test.yml`. Keep a template's
README, prompts, hooks, generated files, and smoke-test expectations in sync.

## Build, Test, and Development Commands

- Read `<template>/README.md` for that template's generation command, supported
  variants, prerequisites, and non-interactive examples.
- Run `./scripts/test-<template>-template.sh` to validate one template.
- Run `for test_script in ./scripts/test-*-template.sh; do "$test_script"; done`
  to execute every template smoke test before repository-wide changes.

Run commands from the repository root. Smoke tests must use temporary directories
and fake external clients; they must not publish packages or create remote
repositories.

## Coding Style & Naming Conventions

Treat each template's checked-in formatter, linter, type-checker, and
`.editorconfig` files as authoritative. Existing templates use UTF-8, LF
endings, final newlines, four-space indentation, a 100-column target, and two
spaces for JSON and YAML. Keep shell scripts POSIX-compatible (`#!/bin/sh`,
`set -eu`). Prompt keys use `snake_case`; generated project slugs use lowercase
letters, digits, hyphens, or underscores. Preserve template expressions exactly
when editing generated paths or file contents.

## Testing Guidelines

Test rendered projects, not only template source. Add cases to the matching
`scripts/test-<template>-template.sh` when changing prompts, hooks, conditional
files, tool configuration, or generated layouts. Follow the generated project's
framework naming conventions and exercise every supported variant. No
repository-wide coverage threshold is configured. Run all smoke scripts before shared
tooling or CI changes.

## Commit & Pull Request Guidelines

History uses Conventional Commit subjects such as `feat:`, `fix:`, `test:`,
and `docs:`; keep each commit focused. Pull requests must complete the repository
template with **Summary**, **Motivation**, and exact **Validation** commands.
Review your own diff, update tests and documentation when needed, link relevant
issues, and call out any intentionally skipped validation.
