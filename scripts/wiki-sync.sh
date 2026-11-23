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
# --check fails (exit 1) when docs/ has a subdirectory, has no .md page, an
# internal .md link points at a page that does not exist or outside docs/, or an
# anchor (Page.md#anchor or a same-page #anchor) matches no heading of its page.
# Anchors are compared with GitHub's heading slugs (lowercase, punctuation
# dropped, spaces to "-", "-1", "-2" for repeats) and with explicit
# <a name="..."> / <a id="..."> targets. Files other than *.md are neither copied
# nor checked.
#
# Exit codes: 0 ok, 1 check failed, 2 usage error.

set -euo pipefail

usage() {
    echo "usage: $(basename "$0") <docs-dir> <out-dir>" >&2
    echo "       $(basename "$0") --check <docs-dir>" >&2
    exit 2
}

# Reads markdown on stdin, writes it with internal .md links stripped of the
# extension. With MODE=check it only reports links, one per line as
# "<line>\x1f<page>\x1f<anchor>" (page is empty for a same-page anchor, anchor
# is empty when the link has none) and writes nothing else. The separator is
# the ASCII unit separator, not a tab, so `read` keeps empty fields.
link_filter() {
    perl -e '
        use strict; use warnings;
        my $mode = $ENV{MODE};
        my $fence = "";
        my $line_no = 0;
        # Internal link: no scheme (":" is excluded), optional "./", target ends in .md.
        my $inline = qr{(\]\()(<?)(\./)?([^)\s#<>:]*?)\.md((?:\#[^)\s>]*)?>?)((?:\s+"[^"]*"|\s+\x27[^\x27]*\x27)?\))};
        my $refdef = qr{^(\s{0,3}\[[^\]]+\]:\s*)(<?)(\./)?([^\s#<>:]*?)\.md((?:\#[^\s>]*)?>?)(\s.*)?$};
        # Same-page anchor link, only reported in check mode.
        my $local = qr{\]\(<?\#([^)\s>]+)>?(?:\s+"[^"]*"|\s+\x27[^\x27]*\x27)?\)};
        sub anchor_of { my $a = shift // ""; $a =~ s/^\#//; $a =~ s/>$//; return $a; }
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
                if ($mode eq "check") { print "$line_no\x1f$4\x1f" . anchor_of($5) . "\n"; next; }
                my ($head, $open, $target, $tail, $rest) = ($1, $2, $4, $5, defined $6 ? $6 : "");
                $rest =~ s/\n$//;
                print $head . $open . $target . $tail . $rest . ($line =~ /\n$/ ? "\n" : "");
                next;
            }

            # Inline code spans are not links: only touch the text between them.
            my @parts = split /(`[^`]*`)/, $line, -1;
            for (my $i = 0; $i < @parts; $i += 2) {
                if ($mode eq "check") {
                    while ($parts[$i] =~ /$inline/g) { print "$line_no\x1f$4\x1f" . anchor_of($5) . "\n"; }
                    while ($parts[$i] =~ /$local/g) { print "$line_no\x1f\x1f$1\n"; }
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

# Prints every anchor a page defines, one per line: GitHub heading slugs (fenced
# code skipped, repeats suffixed "-1", "-2", ...) and explicit
# <a name="..."> / <a id="..."> targets.
heading_slugs() {
    perl -CSD -e '
        use strict; use warnings;
        my ($fence, %seen) = ("");
        while (my $line = <STDIN>) {
            if ($line =~ /^\s{0,3}(`{3,}|~{3,})/) {
                my $marker = substr($1, 0, 1);
                if ($fence eq "") { $fence = $marker; }
                elsif ($fence eq $marker) { $fence = ""; }
                next;
            }
            next if $fence ne "";
            print "$1\n" while $line =~ /<a\s+(?:name|id)="([^"]+)"/g;
            next unless $line =~ /^\s{0,3}#{1,6}\s+(.*?)\s*#*\s*$/;
            my $slug = $1;
            $slug =~ s/!?\[([^\]]*)\]\([^)]*\)/$1/g;  # links and images keep their text
            $slug =~ s/<[^>]+>//g;                     # inline HTML
            $slug = lc $slug;
            $slug =~ s/[^\w\- ]//g;                    # drops ` * \ and other punctuation
            $slug =~ s/ /-/g;
            my $n = $seen{$slug}++;
            print $n ? "$slug-$n\n" : "$slug\n";
        }
    ' < "$1"
}

check_docs() {
    local docs_dir="$1" status=0 entry page name target anchor line_no targets

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
        while IFS=$'\x1f' read -r line_no target anchor; do
            [ -n "${line_no:-}" ] || continue
            case "$target" in
                "")
                    target="${name%.md}"
                    ;;
                */*)
                    echo "${name}:${line_no}: link '${target}.md' points outside docs/ (the wiki is flat)" >&2
                    status=1
                    continue
                    ;;
                *)
                    if [ ! -f "${docs_dir}/${target}.md" ]; then
                        echo "${name}:${line_no}: broken link '${target}.md' (no such page in docs/)" >&2
                        status=1
                        continue
                    fi
                    ;;
            esac
            if [ -n "${anchor:-}" ] && ! heading_slugs "${docs_dir}/${target}.md" | grep -qxF -- "$anchor"; then
                echo "${name}:${line_no}: broken anchor '${target}.md#${anchor}' (no such heading)" >&2
                status=1
            fi
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
