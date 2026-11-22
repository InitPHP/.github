#!/usr/bin/env bash
#
# Turn a package's docs/ directory into GitHub wiki pages (ADR-004).
#
# Usage:
#   wiki-sync.sh <docs-dir> <out-dir>   copy docs/*.md flat into <out-dir>,
#                                       rewriting "](Page.md)" to "](Page)"
#   wiki-sync.sh --check <docs-dir>     validate docs/ without writing anything
#
# Link handling (the same rules apply to --check):
#   - Inline links  [text](Page.md), [text](Page.md#anchor), [text](./Page.md "title")
#   - Reference definitions  [id]: Page.md
#   - Fenced code blocks (``` and ~~~) are left untouched.
#   - Absolute URLs, same-page anchors and non-.md targets are left untouched.
#
# --check fails (exit 1) when docs/ has a subdirectory, has no .md page, or an
# internal .md link points at a page that does not exist or outside docs/.
# Anchors are not verified. Files other than *.md are neither copied nor checked.
#
# Exit codes: 0 ok, 1 check failed, 2 usage error.

set -euo pipefail

usage() {
    echo "usage: $(basename "$0") <docs-dir> <out-dir>" >&2
    echo "       $(basename "$0") --check <docs-dir>" >&2
    exit 2
}

# Reads markdown on stdin, writes it with internal .md links stripped of the
# extension. With MODE=check it only reports link targets (one per line,
# prefixed with the source line number) and writes nothing else.
link_filter() {
    perl -e '
        use strict; use warnings;
        my $mode = $ENV{MODE};
        my $fence = "";
        my $line_no = 0;
        # Internal link: no scheme (":" is excluded), optional "./", target ends in .md.
        my $inline = qr{(\]\()(<?)(\./)?([^)\s#<>:]*?)\.md((?:\#[^)\s>]*)?>?)((?:\s+"[^"]*"|\s+\x27[^\x27]*\x27)?\))};
        my $refdef = qr{^(\s{0,3}\[[^\]]+\]:\s*)(<?)(\./)?([^\s#<>:]*?)\.md((?:\#[^\s>]*)?>?)(\s.*)?$};
        while (my $line = <STDIN>) {
            $line_no++;
            if ($line =~ /^\s{0,3}(`{3,}|~{3,})/) {
                my $marker = substr($1, 0, 1);
                if ($fence eq "") { $fence = $marker; }
                elsif ($fence eq $marker) { $fence = ""; }
                print $line if $mode eq "rewrite";
                next;
            }
            if ($fence ne "") { print $line if $mode eq "rewrite"; next; }

            if ($line =~ $refdef) {
                if ($mode eq "check") { print "$line_no\t$4\n"; next; }
                my ($head, $open, $target, $tail, $rest) = ($1, $2, $4, $5, defined $6 ? $6 : "");
                $rest =~ s/\n$//;
                print $head . $open . $target . $tail . $rest . ($line =~ /\n$/ ? "\n" : "");
                next;
            }

            # Inline code spans are not links: only touch the text between them.
            my @parts = split /(`[^`]*`)/, $line, -1;
            for (my $i = 0; $i < @parts; $i += 2) {
                if ($mode eq "check") {
                    while ($parts[$i] =~ /$inline/g) { print "$line_no\t$4\n"; }
                } else {
                    $parts[$i] =~ s/$inline/$1$2$4$5$6/g;
                }
            }
            print join("", @parts) if $mode eq "rewrite";
        }
    '
}

list_pages() {
    local dir="$1" file
    for file in "$dir"/*.md; do
        [ -e "$file" ] || continue
        [ -f "$file" ] || continue
        printf '%s\n' "$file"
    done
}

check_docs() {
    local docs_dir="$1" status=0 entry page name target line_no targets

    if [ ! -d "$docs_dir" ]; then
        echo "docs directory not found: ${docs_dir}" >&2
        return 1
    fi

    for entry in "$docs_dir"/* "$docs_dir"/.[!.]*; do
        if [ -d "$entry" ]; then
            echo "${entry}: subdirectories are not allowed (the wiki is flat)" >&2
            status=1
        fi
    done

    local pages
    pages="$(list_pages "$docs_dir")"
    if [ -z "$pages" ]; then
        echo "${docs_dir}: no .md pages found" >&2
        return 1
    fi

    while IFS= read -r page; do
        name="$(basename "$page")"
        targets="$(MODE=check link_filter < "$page")"
        while IFS=$'\t' read -r line_no target; do
            [ -n "${target:-}" ] || continue
            case "$target" in
                */*)
                    echo "${name}:${line_no}: link '${target}.md' points outside docs/ (the wiki is flat)" >&2
                    status=1
                    ;;
                *)
                    if [ ! -f "${docs_dir}/${target}.md" ]; then
                        echo "${name}:${line_no}: broken link '${target}.md' (no such page in docs/)" >&2
                        status=1
                    fi
                    ;;
            esac
        done <<< "$targets"
    done <<< "$pages"

    return "$status"
}

sync_docs() {
    local docs_dir="$1" out_dir="$2" page pages

    if [ ! -d "$docs_dir" ]; then
        echo "docs directory not found: ${docs_dir}" >&2
        return 1
    fi

    mkdir -p "$out_dir"
    if [ "$(cd "$docs_dir" && pwd -P)" = "$(cd "$out_dir" && pwd -P)" ]; then
        echo "<out-dir> must differ from <docs-dir>" >&2
        return 1
    fi

    pages="$(list_pages "$docs_dir")"
    while IFS= read -r page; do
        [ -n "$page" ] || continue
        # shellcheck disable=SC2094  # out-dir is verified to differ from docs-dir above
        MODE=rewrite link_filter < "$page" > "${out_dir}/$(basename "$page")"
    done <<< "$pages"
}

case "${1:-}" in
    --check)
        [ "$#" -eq 2 ] || usage
        check_docs "$2"
        ;;
    -*|"")
        usage
        ;;
    *)
        [ "$#" -eq 2 ] || usage
        sync_docs "$1" "$2"
        ;;
esac
