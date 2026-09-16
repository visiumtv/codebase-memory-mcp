#!/usr/bin/env bash
set -euo pipefail

# Install the repo's git hooks into .git/hooks (local, per-clone).
# Currently: commit-msg (strict DCO sign-off enforcement).

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

usage() {
    cat <<'EOF'
Usage: scripts/install-git-hooks.sh

Install this repository's git hooks into .git/hooks (local, per-clone).
Currently: commit-msg, which enforces the DCO sign-off required on every
commit (see CONTRIBUTING.md).

Options:
  -h, --help  Print this help and exit.

Exit codes:
  0 = installed · 2 = usage error.
EOF
}

# STRICT and answered first: this script writes into .git/hooks, so asking it
# for help must not install anything.
for arg in "$@"; do
    case "$arg" in
        -h|--help) usage; exit 0 ;;
        *)
            echo "install-git-hooks.sh: unexpected argument '$arg'. Please consult --help." >&2
            exit 2
            ;;
    esac
done

HOOKS_DIR="$(git -C "$ROOT" rev-parse --git-path hooks)"

install -m 755 "$ROOT/scripts/git-hooks/commit-msg" "$HOOKS_DIR/commit-msg"
echo "installed: $HOOKS_DIR/commit-msg (DCO sign-off required on every commit)"
