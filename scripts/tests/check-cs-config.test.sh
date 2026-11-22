#!/usr/bin/env bash
#
# Tests for scripts/check-cs-config.sh. Run: bash scripts/tests/check-cs-config.test.sh

set -uo pipefail

tests_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script="${tests_dir}/../check-cs-config.sh"
template="${tests_dir}/../../templates/php-cs-fixer.dist.php"
work="$(mktemp -d "${TMPDIR:-/tmp}/check-cs-config-test.XXXXXX")"
trap 'rm -rf "$work"' EXIT

passed=0
failed=0

pass() { passed=$((passed + 1)); echo "ok   - $1"; }
fail() { failed=$((failed + 1)); echo "FAIL - $1"; [ -z "${2:-}" ] || echo "       $2"; }

# expect_status <name> <expected-status> <package-dir>
expect_status() {
    local actual
    bash "$script" "$3" > /dev/null 2> "${work}/stderr"
    actual=$?
    if [ "$actual" -eq "$2" ]; then
        pass "$1"
    else
        fail "$1" "expected exit $2, got ${actual}: $(cat "${work}/stderr")"
    fi
}

new_package() {
    mkdir -p "${work}/$1"
    cp "$template" "${work}/$1/.php-cs-fixer.dist.php"
}

new_package identical
expect_status "identical copy passes" 0 "${work}/identical"

new_package excluded
sed -i.bak "s#^\\\$excludeDirs = .*#\$excludeDirs = ['Unit/FileLanguages', 'Unit/Fixtures'];#; s#^\\\$excludePaths = .*#\$excludePaths = ['Stubs/aws-sdk.php'];#" "${work}/excluded/.php-cs-fixer.dist.php"
rm "${work}/excluded/.php-cs-fixer.dist.php.bak"
expect_status "package-specific exclude lines are ignored" 0 "${work}/excluded"

new_package drifted
sed -i.bak "s#'single_quote' => true,#'single_quote' => false,#" "${work}/drifted/.php-cs-fixer.dist.php"
rm "${work}/drifted/.php-cs-fixer.dist.php.bak"
expect_status "a changed rule fails" 1 "${work}/drifted"
if grep -q "differs from the shared template" "${work}/stderr"; then pass "drift is reported"; else fail "drift is reported" "$(cat "${work}/stderr")"; fi

new_package missing-line
grep -v 'excludePaths = ' "${work}/missing-line/.php-cs-fixer.dist.php" > "${work}/missing-line/cfg" && mv "${work}/missing-line/cfg" "${work}/missing-line/.php-cs-fixer.dist.php"
expect_status "a missing exclude line fails" 1 "${work}/missing-line"

new_package stale-override
touch "${work}/stale-override/.php-cs-fixer.php"
expect_status "a leftover .php-cs-fixer.php fails" 1 "${work}/stale-override"

mkdir -p "${work}/no-config"
expect_status "a missing config fails" 1 "${work}/no-config"

bash "$script" > /dev/null 2>&1
if [ "$?" -eq 2 ]; then pass "usage: no arguments exits 2"; else fail "usage: no arguments exits 2"; fi

echo
echo "${passed} passed, ${failed} failed"
[ "$failed" -eq 0 ]
