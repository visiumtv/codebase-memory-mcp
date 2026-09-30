#!/usr/bin/env bash
set -euo pipefail

# Generates the third-party notices bundle shipped inside every release
# archive: THIRD_PARTY.md + the grammar provenance manifest + the verbatim
# license/notice text of every vendored component (both vendored trees).
# Deterministic output (sorted file order).

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

usage() {
    cat <<'EOF'
Usage: scripts/gen-third-party-notices.sh [output-path]

Generate the third-party notices bundle shipped inside every release archive:
THIRD_PARTY.md, the grammar provenance manifest, and the verbatim license /
notice text of every vendored component in both vendored trees. Output is
deterministic (sorted file order).

  output-path   Where to write (default: build/THIRD_PARTY_NOTICES.md).

Options:
  -h, --help    Print this help and exit.

Exit codes:
  0 = written · 2 = usage error.
EOF
}

# Answered before OUT is derived from $1: otherwise `--help` was taken as the
# output path and the script wrote a 563 KB file literally named "--help"
# into the working directory.
case "${1:-}" in
    -h|--help) usage; exit 0 ;;
    -*) echo "gen-third-party-notices.sh: unknown option '$1'. Please consult --help." >&2; exit 2 ;;
esac
if [ "$#" -gt 1 ]; then
    echo "gen-third-party-notices.sh: expected at most one output path. Please consult --help." >&2
    exit 2
fi

OUT="${1:-$ROOT/build/THIRD_PARTY_NOTICES.md}"
mkdir -p "$(dirname "$OUT")"

{
    echo "# Third-Party Notices"
    echo
    echo "This file accompanies the codebase-memory-mcp binary distribution."
    echo "It aggregates THIRD_PARTY.md, the vendored grammar provenance"
    echo "manifest, and the verbatim license / notice texts of every vendored"
    echo "component, satisfying binary-redistribution notice requirements"
    echo "(MIT, BSD, Apache-2.0)."
    echo
    echo "---"
    echo
    cat "$ROOT/THIRD_PARTY.md"
    echo
    echo "---"
    echo
    cat "$ROOT/internal/cbm/vendored/grammars/MANIFEST.md"

    find "$ROOT/vendored" "$ROOT/internal/cbm/vendored" -type f \
        \( -iname 'LICENSE*' -o -iname 'COPYING*' -o -iname 'NOTICE*' -o -iname 'UNLICENSE*' \) \
        | LC_ALL=C sort | while IFS= read -r f; do
        rel="${f#"$ROOT"/}"
        echo
        echo "==============================================================="
        echo "  $rel"
        echo "==============================================================="
        echo
        cat "$f"
    done

    # With-ui packaging path: node_modules exists (make frontend ran npm ci),
    # so append the license texts of the npm packages compiled into the
    # external UI pack. Standard archives carry no pack — the section is
    # skipped.
    if [ -d "$ROOT/graph-ui/node_modules" ]; then
        echo
        echo "---"
        echo
        python3 "$ROOT/scripts/gen-ui-licenses.py" "$ROOT/graph-ui"
    fi
} > "$OUT"

BYTES=$(wc -c < "$OUT" | tr -d ' ')
echo "wrote $OUT (${BYTES} bytes)"
