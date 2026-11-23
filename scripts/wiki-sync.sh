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
# anchor (Page.md#anchor or a same-page #anchor, in an inline link or a reference
# definition) matches no anchor of its page. The anchors of a page are the
# heading slugs GitHub renders from the heading text (see heading_slugs below),
# the id= / name= attributes of its HTML tags, and "top". Matching is exact and
# case-sensitive; a percent-encoded anchor is decoded first. Files other than
# *.md are neither copied nor checked.
#
# Known limits of the anchor check (it is not a markdown renderer): HTML tags
# split over several lines are not read; only a short list of named entities is
# decoded (&amp; &lt; &copy; ... and numeric ones); a fenced block indented four
# or more spaces (inside a nested list) is not recognised as a fence; YAML front
# matter and raw HTML blocks other than single-line <hN> headings are not
# interpreted. The slug of a heading is checked against GitHub's own rendering
# in tests/fixtures/anchor-slugs.
#
# Exit codes: 0 ok, 1 check failed, 2 usage error.

set -euo pipefail

usage() {
    echo "usage: $(basename "$0") <docs-dir> <out-dir>" >&2
    echo "       $(basename "$0") --check <docs-dir>" >&2
    exit 2
}

# Perl source shared by link_filter and heading_slugs, so both see the same
# fences and the same protected spans. It holds no single quote: it is pasted
# in front of each program as a shell variable.
#   fence_line($line)  1 when the line opens, closes or sits inside a fenced code
#                      block. A fence closes only on the same character, at least
#                      as long as the opening one and with nothing after it; a
#                      backtick fence whose info string holds a backtick is
#                      inline code, not a fence.
#   quote_body($line)  the line without its leading "> " markers.
#   protect($line)     replaces code spans and backslash escapes with
#                      placeholders so no later rule reads inside them;
#                      restore($text, "raw"|"text") puts them back, as written or
#                      as the characters the reader sees.
# shellcheck disable=SC2016  # perl source, not shell
PERL_COMMON='
use strict; use warnings;
my ($fence_char, $fence_len) = ("", 0);
my @stash;
sub fence_line {
    my $l = shift;
    if ($fence_char eq "") {
        return 0 unless $l =~ /^\s{0,3}(`{3,}|~{3,})(.*)$/;
        my ($run, $info) = ($1, $2);
        return 0 if substr($run, 0, 1) eq "`" && $info =~ /`/;
        ($fence_char, $fence_len) = (substr($run, 0, 1), length $run);
        return 1;
    }
    if ($l =~ /^\s{0,3}(`{3,}|~{3,})\s*$/ && substr($1, 0, 1) eq $fence_char && length($1) >= $fence_len) {
        ($fence_char, $fence_len) = ("", 0);
    }
    return 1;
}
sub quote_body { my $l = shift; $l =~ s/^(?:[ \t]{0,3}>[ \t]?)+//; return $l; }
sub protect {
    my $s = shift;
    $s =~ s{\\([\x21-\x2f\x3a-\x40\x5b-\x60\x7b-\x7e])|(?<!`)(`+)(?!`)(.+?)(?<!`)\2(?!`)}{
        my ($raw, $i) = ($&, scalar @stash);
        if (defined $1) {
            push @stash, { raw => $raw, text => $1 };
        } else {
            my $c = $3;
            $c =~ s/\n/ /g;
            $c =~ s/^ (.*) $/$1/ if $c =~ /[^ ]/;
            push @stash, { raw => $raw, text => $c };
        }
        "\x1d$i\x1e";
    }ge;
    return $s;
}
sub restore { my ($s, $kind) = @_; $s =~ s/\x1d(\d+)\x1e/$stash[$1]{$kind}/g; return $s; }
'

# Reads markdown on stdin, writes it with internal .md links stripped of the
# extension. With MODE=check it only reports links, one per line as
# "<line>\x1f<page>\x1f<anchor>" (page is empty for a same-page anchor, anchor
# is empty when the link has none, a percent-encoded anchor is decoded) and
# writes nothing else. The separator is the ASCII unit separator, not a tab, so
# `read` keeps empty fields.
link_filter() {
    perl -e "$PERL_COMMON"'
        my $mode = $ENV{MODE};
        my $line_no = 0;
        # Internal link: no scheme (":" is excluded), optional "./", target ends in .md.
        my $inline = qr{(\]\()(<?)(\./)?([^)\s#<>:]*?)\.md((?:\#[^)\s>]*)?>?)((?:\s+"[^"]*"|\s+\x27[^\x27]*\x27)?\))};
        my $refdef = qr{^(\s{0,3}\[[^\]]+\]:\s*)(<?)(\./)?([^\s#<>:]*?)\.md((?:\#[^\s>]*)?>?)(\s.*)?$};
        # Same-page anchors, only reported in check mode: inline link and reference definition.
        my $local = qr{\]\(<?\#([^)\s>]+)>?(?:\s+"[^"]*"|\s+\x27[^\x27]*\x27)?\)};
        my $refdef_local = qr{^\s{0,3}\[[^\]]+\]:\s*<?\#([^\s>]+)>?(?:\s.*)?$};
        sub anchor_of {
            my $a = shift // "";
            $a =~ s/^\#//; $a =~ s/>$//;
            $a =~ s/%([0-9A-Fa-f]{2})/chr hex $1/ge;
            return restore($a, "text");
        }
        sub target_of { return restore(shift, "text"); }
        while (my $line = <STDIN>) {
            $line_no++;
            if (fence_line(quote_body($line))) { print $line if $mode eq "rewrite"; next; }

            my $work = protect($line);
            if ($work =~ $refdef) {
                if ($mode eq "check") { print "$line_no\x1f" . target_of($4) . "\x1f" . anchor_of($5) . "\n"; next; }
                my ($head, $open, $target, $tail, $rest) = ($1, $2, $4, $5, defined $6 ? $6 : "");
                $rest =~ s/\n$//;
                print restore($head . $open . $target . $tail . $rest, "raw") . ($line =~ /\n$/ ? "\n" : "");
                next;
            }
            if ($mode eq "check") {
                print "$line_no\x1f\x1f" . anchor_of($1) . "\n" if $work =~ $refdef_local;
                while ($work =~ /$inline/g) { print "$line_no\x1f" . target_of($4) . "\x1f" . anchor_of($5) . "\n"; }
                while ($work =~ /$local/g) { print "$line_no\x1f\x1f" . anchor_of($1) . "\n"; }
            } else {
                $work =~ s/$inline/$1$2$4$5$6/g;
                print restore($work, "raw");
            }
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

# Prints every anchor a page defines, one per line, in document order: the
# heading slugs GitHub renders (ATX, setext and <hN> headings, also inside block
# quotes and list items; repeats suffixed "-1", "-2", ...) and explicit id= /
# name= targets. The slug is built from the rendered heading text, not the
# markdown source: code spans keep their text, emphasis, links, tags and
# entities are resolved first, images count as nothing, and what is not a word
# character, "-" or a space is dropped. Fenced code, code spans and HTML
# comments define nothing. Exits non-zero when the page cannot be read.
heading_slugs() {
    perl -CSD -e "$PERL_COMMON"'
        my $dest  = qr{(?:<[^>]*>|(?:[^()\s]|\([^()]*\))*)};
        my $title = qr{(?:\s+"[^"]*"|\s+\x27[^\x27]*\x27|\s+\([^)]*\))?};
        my $paren = qr{\(\s*$dest$title\s*\)};
        my %entity = (
            amp => "&", lt => "<", gt => ">", quot => "\"", apos => "\x27", nbsp => "\x{a0}",
            copy => "\x{a9}", reg => "\x{ae}", trade => "\x{2122}", hellip => "\x{2026}",
            mdash => "\x{2014}", ndash => "\x{2013}", laquo => "\x{ab}", raquo => "\x{bb}",
            lsquo => "\x{2018}", rsquo => "\x{2019}", ldquo => "\x{201c}", rdquo => "\x{201d}",
            middot => "\x{b7}", times => "\x{d7}", larr => "\x{2190}", rarr => "\x{2192}",
            check => "\x{2713}", bull => "\x{2022}", deg => "\x{b0}", plusmn => "\x{b1}",
        );
        sub norm_label { my $l = lc shift; $l =~ s/\s+/ /g; $l =~ s/^ //; $l =~ s/ $//; return $l; }
        sub trim { my $t = shift; $t =~ s/^\s+//; $t =~ s/\s+$//; return $t; }
        sub codepoint {
            my $n = shift;
            return "\x{fffd}" if $n == 0 || $n > 0x10ffff || ($n >= 0xd800 && $n <= 0xdfff);
            return chr $n;
        }

        my @lines = <STDIN>;
        my %refs;
        foreach my $l (@lines) { $refs{norm_label($1)} = 1 if $l =~ /^\s{0,3}\[([^\]]+)\]:/; }

        # The text a reader sees for inline markdown, reduced to a GitHub slug.
        sub slug_of {
            my $s = shift;
            $s =~ s/!\[[^\]]*\](?:$paren|\[[^\]]*\])//g;
            $s =~ s{\[((?:[^\[\]]|\[[^\[\]]*\])*)\](?:$paren|\[([^\]]*)\])}{
                defined $2 ? (($2 eq "" || $refs{norm_label($2)}) ? $1 : $&) : $1
            }ge;
            $s =~ s/<([A-Za-z][A-Za-z0-9+.\-]{1,31}:[^\s<>]*)>/$1/g;
            $s =~ s/<\/?[A-Za-z][A-Za-z0-9\-]*(?:\s[^<>]*)?\/?>//g;
            for (1 .. 3) {
                last unless $s =~ s/(?<![\p{L}\p{N}_])(_{1,3})(?=[^\s_])(.+?)(?<=[^\s_])\1(?![\p{L}\p{N}_])/$2/g;
            }
            $s =~ s{&(?:#([0-9]+)|#[xX]([0-9A-Fa-f]+)|([A-Za-z][A-Za-z0-9]*));}{
                defined $1 ? codepoint($1) : defined $2 ? codepoint(hex $2) : exists $entity{$3} ? $entity{$3} : $&
            }ge;
            $s = lc restore($s, "text");
            $s =~ s/[^\w\- ]//g;
            $s =~ s/ /-/g;
            return $s;
        }

        my %seen;
        sub emit_slug {
            my $base = shift;
            my $slug = $base;
            while (exists $seen{$slug}) { $seen{$base}++; $slug = "$base-$seen{$base}"; }
            $seen{$slug} = 0;
            print "$slug\n";
        }

        my ($comment, @para) = (0);
        foreach my $raw (@lines) {
            $raw =~ s/\r?\n$//;
            my $body = quote_body($raw);
            if ($comment) {
                next unless $body =~ s/^.*?-->//;
                $comment = 0;
            }
            if (fence_line($body)) { @para = (); next; }
            my $line = protect($body);
            $line =~ s/<!--.*?-->//g;
            $comment = 1 if $line =~ s/<!--.*$//;

            while ($line =~ /(<[A-Za-z][^<>]*>)/g) {
                my $tag = $1;
                while ($tag =~ /\s(?:id|name)\s*=\s*(?:"([^"]*)"|\x27([^\x27]*)\x27|([^\s"\x27>]+))/gi) {
                    print restore(defined $1 ? $1 : defined $2 ? $2 : $3, "text") . "\n";
                }
            }

            $line =~ s/^\s*(?:[-*+]|\d{1,9}[.)])[ \t]+(?=\#{1,6}(?:[ \t]|$))//;
            if ($line =~ /^\s{0,3}\#{1,6}(?:[ \t]+(.*?))?[ \t]*$/) {
                my $text = defined $1 ? $1 : "";
                $text =~ s/(?:^|[ \t]+)\#+$//;
                emit_slug(slug_of($text));
                @para = ();
                next;
            }
            emit_slug(slug_of($2)) while $line =~ m{<h([1-6])\b[^<>]*>(.*?)</h\1\s*>}gi;

            if (@para && $line =~ /^\s{0,3}(?:=+|-+)[ \t]*$/) {
                emit_slug(slug_of(join "", map { trim($_) } @para));
                @para = ();
                next;
            }
            my $starts_block = $line =~ /^\s{4,}/
                || $line =~ /^\s{0,3}(?:[-*+]|\d{1,9}[.)])(?:[ \t]|$)/
                || $line =~ /^\s{0,3}(?:<|\||\[[^\]]+\]:)/
                || $line =~ /^\s{0,3}([-*_])(?:[ \t]*\1){2,}[ \t]*$/;
            if ($line =~ /^\s*$/ || $starts_block) { @para = (); next; }
            push @para, $line;
        }
    ' < "$1"
}

# True when the page named by $1 has an anchor $2. "top" always exists: browsers
# scroll to the top of the page for it.
anchor_exists() {
    local page="$1" anchor="$2" slugs
    case "$anchor" in
        [Tt][Oo][Pp]) return 0 ;;
    esac
    # Read the whole list before searching it: a pipe into `grep -q` would hit
    # SIGPIPE once grep stops reading early, and pipefail turns that into
    # "anchor not found" for long pages.
    if ! slugs="$(heading_slugs "$page" 2> /dev/null)"; then
        echo "${page}: cannot read the headings (is the file valid UTF-8?)" >&2
        return 2
    fi
    grep -xF -- "$anchor" > /dev/null <<< "$slugs"
}

check_docs() {
    local docs_dir="$1" status=0 found entry page name target anchor line_no targets

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
            if [ -n "${anchor:-}" ]; then
                found=0
                anchor_exists "${docs_dir}/${target}.md" "$anchor" || found=$?
                if [ "$found" -eq 1 ]; then
                    echo "${name}:${line_no}: broken anchor '${target}.md#${anchor}' (no such heading)" >&2
                    status=1
                elif [ "$found" -ne 0 ]; then
                    status=1
                fi
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
