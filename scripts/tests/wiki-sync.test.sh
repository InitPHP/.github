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
expect_stderr_contains "check: a prefix of a slug is not a match" "Home.md:7: broken anchor 'Other.md#pres'"
expect_stderr_contains "check: anchors are case-sensitive" "Home.md:8: broken anchor 'Other.md#Present'"
expect_stderr_contains "check: code span text stays in the slug" "Home.md:9: broken anchor 'Home.md#the-collection-class'"
expect_stderr_contains "check: a shorter fence marker does not close a ~~~ fence" "Home.md:10: broken anchor 'Home.md#fake-tilde'"
expect_stderr_contains "check: a shorter fence marker does not close a longer fence" "Home.md:11: broken anchor 'Home.md#fake-long'"
expect_stderr_contains "check: headings inside HTML comments are not targets" "Home.md:12: broken anchor 'Home.md#commented-out'"
expect_stderr_contains "check: a code span is not an explicit target" "Home.md:13: broken anchor 'Home.md#inline-name'"
expect_stderr_contains "check: percent-encoded anchors are decoded" "Home.md:14: broken anchor 'Home.md#öx'"
expect_stderr_contains "check: an explicit target inside an HTML comment does not count" "Home.md:15: broken anchor 'Home.md#hidden'"
expect_stderr_contains "check: reference definitions are checked across pages" "Home.md:17: broken anchor 'Other.md#nope-ref'"
expect_stderr_contains "check: reference definitions are checked on the same page" "Home.md:18: broken anchor 'Home.md#gone-local'"
expect_stderr_contains "check: text in a list item is not a setext heading" "Home.md:44: broken anchor 'Home.md#continued-item-text'"
expect_stderr_contains "check: a quoted paragraph is not closed by an underline outside the quote" "Home.md:45: broken anchor 'Home.md#quoted-para'"
expect_stderr_contains "check: text in an HTML block is not a setext heading" "Home.md:46: broken anchor 'Home.md#html-text'"
expect_stderr_contains "check: a lazy continuation line is not a setext heading" "Home.md:47: broken anchor 'Home.md#lazy-line'"
expect_stderr_contains "check: a block-level tag starts an HTML block" "Home.md:48: broken anchor 'Home.md#text-here'"
expect_stderr_contains "check: indented code is not a setext heading" "Home.md:49: broken anchor 'Home.md#indented-code'"
# Exactly the twenty broken anchors above, nothing else (the existing anchors stay accepted).
if [ "$(grep -c 'broken anchor' "${work}/stderr")" -eq 20 ] && ! grep -qF "Other.md#present" "${work}/stderr"; then
    pass "check: reports exactly the broken anchors and accepts an existing one"
else
    fail "check: reports exactly the broken anchors and accepts an existing one" "$(cat "${work}/stderr")"
fi

# A page whose slug list is far larger than a pipe buffer, with the wanted anchor
# first: `grep -q` used to quit early, perl got SIGPIPE and pipefail reported a
# broken anchor.
long_docs="${work}/long/docs"
mkdir -p "$long_docs"
printf '# Home\n\n[first](Long.md#first-heading)\n[last](Long.md#heading-number-3999)\n' > "${long_docs}/Home.md"
{
    echo "# First heading"
    n=0
    while [ "$n" -lt 4000 ]; do
        echo "## Heading number ${n}"
        n=$((n + 1))
    done
} > "${long_docs}/Long.md"
repeat=0
long_failed=0
while [ "$repeat" -lt 5 ]; do
    bash "$script" --check "$long_docs" > /dev/null 2>&1 || long_failed=$((long_failed + 1))
    repeat=$((repeat + 1))
done
if [ "$long_failed" -eq 0 ]; then
    pass "check: a long page does not give a false broken anchor (SIGPIPE)"
else
    fail "check: a long page does not give a false broken anchor (SIGPIPE)" "${long_failed} of 5 runs failed"
fi

# Invalid UTF-8 in a heading must be reported as unreadable, not as a missing anchor.
bad_docs="${work}/bad/docs"
mkdir -p "$bad_docs"
printf '# Home\n\n[x](Other.md#ok)\n' > "${bad_docs}/Home.md"
printf '# Other\n\n## ok\n\n## broken \377\376 heading\n' > "${bad_docs}/Other.md"
expect_status "check: a page that cannot be read fails" 1 bash "$script" --check "$bad_docs"
expect_stderr_contains "check: says the page cannot be read" "cannot read the headings"
if grep -qF "broken anchor" "${work}/stderr"; then
    fail "check: an unreadable page is not reported as a broken anchor" "$(cat "${work}/stderr")"
else
    pass "check: an unreadable page is not reported as a broken anchor"
fi

# A fence inside a block quote ends with the quote; "> ```" lines inside an outer
# fence are plain code. Only Gone2, Gone4 and Gone5 and the fake heading are broken.
expect_status "check: block quote fences" 1 bash "$script" --check "${fixtures}/blockquote-fence/docs"
expect_stderr_contains "check: a link after a fence that held quoted fences is checked" "Home.md:10: broken link 'Gone2.md'"
expect_stderr_contains "check: a link after a quoted fence is checked" "Home.md:16: broken link 'Gone4.md'"
expect_stderr_contains "check: a quoted fence ends with the quote" "Home.md:21: broken link 'Gone5.md'"
expect_stderr_contains "check: a heading inside quoted code is no target" "Home.md:26: broken anchor 'Home.md#fake-outer'"
if [ "$(grep -c 'broken' "${work}/stderr")" -eq 4 ]; then
    pass "check: links inside fences are not reported"
else
    fail "check: links inside fences are not reported" "$(cat "${work}/stderr")"
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
