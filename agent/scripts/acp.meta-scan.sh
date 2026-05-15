#!/usr/bin/env bash
# DEPRECATED — acp.meta-scan.sh
#
# This script scanned for @acp.meta.* markers. That marker format has been
# retired. ACP now uses @scry.entry markers (scry-spec v1.0) for all artifact
# metadata.
#
# Replace with:
#   scry-parse-py  — https://pypi.org/project/scry-parse-py
#   scry-parse-ts  — https://www.npmjs.com/package/scry-parse-ts
#
# Or, if your project is bound to the scry MCP driver, query via scry_sql:
#   SELECT id, kind, summary FROM scry__doc WHERE kind = 'task'
#
# This file is retained for historical reference only. It will not produce
# useful output on a migrated codebase.
#
# ============================================================================
# ORIGINAL DOCUMENTATION (historical):
# acp.meta-scan.sh — find and parse @acp.meta.* markers across any file type.
#
# Markers are language-agnostic metadata blocks of the form:
#
#     <!-- @acp.meta.spec          (or // # -- ;; * (* — any comment syntax)
#     topic: ...
#     requirements: R1..R30
#     @acp.meta.end -->
#
# The opening sentinel is literally `@acp.meta.<kind>`; the closing is
# literally `@acp.meta.end`. Comment characters (<!-- // # -- ;; *) are
# stripped during parsing. Works in markdown, TS, Python, SQL, shell, Rust,
# YAML, and any file where a comment can contain those two sentinels.
#
# Usage:
#   acp.meta-scan.sh [root]                    # scan entire tree (default .)
#   acp.meta-scan.sh --kind spec [root]        # only spec markers
#   acp.meta-scan.sh --kind task,code [root]   # only task + code markers
#
# Output (one flat stream, '---' between blocks):
#   file: path/to/file.md
#   kind: task
#   topic: wire parser
#   covers: R31, R32
#   ---
#   file: src/thing.ts
#   kind: code
#   implements: R31
#   ---

set -eu

root="."
kinds=""

while [ $# -gt 0 ]; do
    case "$1" in
        --kind)
            kinds="$2"
            shift 2
            ;;
        -h|--help)
            sed -n 's/^# //;3,27p' "$0"
            exit 0
            ;;
        *)
            root="$1"
            shift
            ;;
    esac
done

if [ ! -e "$root" ]; then
    echo "acp.meta-scan.sh: root not found: $root" >&2
    exit 1
fi

# Find files that contain at least one marker. grep -l short-circuits per file.
# Skip node_modules, .git, dist, build, and other common vendor dirs.
# agent/drivers/ is reserved for driver-managed state (design DR16); never recurse into it.
files=$(grep -rl \
    --exclude-dir=node_modules \
    --exclude-dir=.git \
    --exclude-dir=dist \
    --exclude-dir=build \
    --exclude-dir=.next \
    --exclude-dir=.wrangler \
    --exclude-dir=coverage \
    --exclude-dir=drivers \
    '@acp\.meta\.' "$root" 2>/dev/null || true)

if [ -z "$files" ]; then
    exit 0
fi

# Pipe file list to awk as stdin; awk reads filenames and processes each.
# Using xargs ensures proper handling of paths with spaces or newlines.
printf '%s\n' "$files" | xargs -d '\n' awk -v kinds="$kinds" '
    function strip(s) {
        # Strip a leading run of comment characters + whitespace.
        # Handles: <!-- // -- # ;; * (*
        sub(/^[[:space:]]*(<!--|\/\/|--|#|;;|\*|\(\*)[[:space:]]*/, "", s)
        return s
    }

    BEGIN {
        if (kinds != "") {
            n = split(kinds, want, ",")
            for (i = 1; i <= n; i++) {
                gsub(/[[:space:]]/, "", want[i])
                want_set[want[i]] = 1
            }
        }
    }

    # End-of-block: emit separator and clear state
    /@acp\.meta\.end/ {
        if (inblk) printf "---\n"
        inblk = 0
        next
    }

    # Start-of-block: extract kind, emit header (if kind allowed)
    /@acp\.meta\.[a-z]+/ {
        line = strip($0)
        sub(/.*@acp\.meta\./, "", line)
        # trim trailing markdown closing fence or block-comment terminator
        sub(/[[:space:]-]*(-->|\*\/).*/, "", line)
        gsub(/[[:space:]]/, "", line)
        kind = line

        if (kinds != "" && !(kind in want_set)) {
            inblk = 0
            next
        }

        inblk = 1
        printf "file: %s\nkind: %s\n", FILENAME, kind
        next
    }

    # Body line within a block: strip comment, emit if it looks like key: value
    inblk {
        line = strip($0)
        # trim trailing block-comment closers
        sub(/[[:space:]]*(-->|\*\/)[[:space:]]*$/, "", line)
        if (line ~ /^[a-z_]+:/) {
            print line
        }
    }
'
