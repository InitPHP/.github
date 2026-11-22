#!/usr/bin/env bash
#
# Verify that a package uses the shared php-cs-fixer configuration (ADR-005).
#
# Usage: check-cs-config.sh <package-dir>
#
# Compares <package-dir>/.php-cs-fixer.dist.php with templates/php-cs-fixer.dist.php,
# ignoring the two package-specific lines ($excludeDirs / $excludePaths). A package
# must carry exactly one of each, each on a single line, and must not ship a
# `.php-cs-fixer.php` (php-cs-fixer prefers it over the `.dist` file).
#
# Exit codes: 0 identical, 1 differs, 2 usage error.

set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "usage: $(basename "$0") <package-dir>" >&2
    exit 2
fi

package_dir="$1"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
template="${script_dir}/../templates/php-cs-fixer.dist.php"
config="${package_dir}/.php-cs-fixer.dist.php"
package_name="$(basename "$(cd "$package_dir" && pwd)")"

if [ ! -f "$template" ]; then
    echo "${package_name}: template not found at ${template}" >&2
    exit 2
fi

if [ ! -f "$config" ]; then
    echo "${package_name}: .php-cs-fixer.dist.php is missing" >&2
    exit 1
fi

status=0

if [ -e "${package_dir}/.php-cs-fixer.php" ]; then
    echo "${package_name}: .php-cs-fixer.php must not exist (it overrides .php-cs-fixer.dist.php)" >&2
    status=1
fi

# The two lines may only hold a single-quoted string-literal list, e.g.
# $excludeDirs = ['Unit/Fixtures', 'Stubs']; anything else (extra statements,
# expressions) stays in the diff and fails the check.
string_list="\\[('[^'\\\\]*'(, '[^'\\\\]*')*)?\\];"

for variable in excludeDirs excludePaths; do
    count="$(grep -cE "^\\\$${variable} = ${string_list}\$" "$config" || true)"
    if [ "$count" -ne 1 ]; then
        echo "${package_name}: expected exactly one \$${variable} assignment holding only a single-line list of single-quoted strings, found ${count}" >&2
        status=1
    fi
done

exclude_regex="^\\\$exclude(Dirs|Paths) = ${string_list}\$"

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/check-cs-config.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT
grep -vE "$exclude_regex" "$template" > "${work_dir}/template.php" || true
grep -vE "$exclude_regex" "$config" > "${work_dir}/package.php" || true

if ! diff -u --label "template" --label "${package_name}/.php-cs-fixer.dist.php" \
    "${work_dir}/template.php" "${work_dir}/package.php" >&2; then
    echo "${package_name}: .php-cs-fixer.dist.php differs from the shared template" >&2
    status=1
fi

exit "$status"
