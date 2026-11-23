#!/usr/bin/env bash
#
# Tests for scripts/wiki-sync.sh. Run: bash scripts/tests/wiki-sync.test.sh

set -uo pipefail

tests_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script="${tests_dir}/../wiki-sync.sh"
fixtures="${tests_dir}/fixtures"
work="$(mktemp -d "${TMPDIR:-/tmp}/wiki-sync-test.XXXXXX")"
trap 'rm -rf "$work"' EXIT

passed=0
failed=0

pass() { passed=$((passed + 1)); echo "ok   - $1"; }
fail() { failed=$((failed + 1)); echo "FAIL - $1"; [ -z "${2:-}" ] || echo "       $2"; }

# expect_status <name> <expected-status> <command...>; stderr is kept in $work/stderr.
expect_status() {
    local name="$1" expected="$2" actual
    shift 2
    "$@" > "${work}/stdout" 2> "${work}/stderr"
    actual=$?
    if [ "$actual" -eq "$expected" ]; then
        pass "$name"
    else
        fail "$name" "expected exit ${expected}, got ${actual}: $(cat "${work}/stderr")"
    fi
}

expect_stderr_contains() {
    if grep -qF -- "$2" "${work}/stderr"; then
        pass "$1"
    else
        fail "$1" "stderr does not contain '$2': $(cat "${work}/stderr")"
    fi
}

# --- sync -------------------------------------------------------------------

expect_status "sync: valid docs convert" 0 bash "$script" "${fixtures}/valid/docs" "${work}/out"

if diff -r "${fixtures}/valid/expected" "${work}/out" > "${work}/diff"; then
    pass "sync: output equals expected fixture"
else
    fail "sync: output equals expected fixture" "$(cat "${work}/diff")"
fi

if [ ! -e "${work}/out/diagram.txt" ]; then
    pass "sync: non-markdown files are not copied"
else
    fail "sync: non-markdown files are not copied"
fi

expect_status "sync: converting converted pages is a no-op" 0 bash "$script" "${work}/out" "${work}/out2"
if diff -r "${work}/out" "${work}/out2" > "${work}/diff"; then
    pass "sync: idempotent"
else
    fail "sync: idempotent" "$(cat "${work}/diff")"
fi

expect_status "sync: creates a missing out-dir" 0 bash "$script" "${fixtures}/valid/docs" "${work}/new/nested/out"
expect_status "sync: refuses out-dir equal to docs-dir" 1 bash "$script" "${work}/out" "${work}/out"
expect_stderr_contains "sync: explains the out-dir refusal" "must differ"
expect_status "sync: missing docs-dir fails" 1 bash "$script" "${work}/absent" "${work}/o3"

# --- check ------------------------------------------------------------------

expect_status "check: valid docs pass" 0 bash "$script" --check "${fixtures}/valid/docs"

expect_status "check: broken link fails" 1 bash "$script" --check "${fixtures}/broken-link/docs"
expect_stderr_contains "check: names the broken link" "Home.md:3: broken link 'Nope.md'"

expect_status "check: link leaving docs/ fails" 1 bash "$script" --check "${fixtures}/outside-link/docs"
expect_stderr_contains "check: names the outside link" "../README.md"

expect_status "check: anchors match GitHub heading slugs" 0 bash "$script" --check "${fixtures}/anchor-slugs/docs"

expect_status "check: broken anchor fails" 1 bash "$script" --check "${fixtures}/broken-anchor/docs"
expect_stderr_contains "check: names the broken cross-page anchor" "Home.md:3: broken anchor 'Other.md#nope'"
expect_stderr_contains "check: names the broken same-page anchor" "Home.md:4: broken anchor 'Home.md#absent'"
expect_stderr_contains "check: ignores headings inside fences" "Home.md:5: broken anchor 'Home.md#fenced-heading'"
if grep -qF "Other.md#present" "${work}/stderr"; then
    fail "check: accepts an existing anchor" "$(cat "${work}/stderr")"
else
    pass "check: accepts an existing anchor"
fi

expect_status "check: subdirectory fails" 1 bash "$script" --check "${fixtures}/subdir/docs"
expect_stderr_contains "check: names the subdirectory" "subdirectories are not allowed"

expect_status "check: directory without pages fails" 1 bash "$script" --check "${fixtures}/empty/docs"
expect_status "check: missing docs-dir fails" 1 bash "$script" --check "${work}/absent"

# --- usage ------------------------------------------------------------------

expect_status "usage: no arguments" 2 bash "$script"
expect_status "usage: sync with one argument" 2 bash "$script" "${fixtures}/valid/docs"
expect_status "usage: --check without directory" 2 bash "$script" --check
expect_status "usage: unknown option" 2 bash "$script" --nope x

echo
echo "${passed} passed, ${failed} failed"
[ "$failed" -eq 0 ]
