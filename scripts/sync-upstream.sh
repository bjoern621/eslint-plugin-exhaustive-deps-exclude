#!/usr/bin/env bash
# Merges the current eslint-plugin-react-hooks sources into src/ over the pinned revision.
# Usage: sync-upstream.sh [--check] [--ref <git ref>]
# --check reports drift and writes nothing.
# Exit 0 clean, 1 conflicts written as markers, 2 drift under --check, 3 fetch failed.
set -uo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root" || exit 3

UPSTREAM_REPO=${UPSTREAM_REPO:-facebook/react}
UPSTREAM_DIR=packages/eslint-plugin-react-hooks/src

# Pristine copy, live file, path under UPSTREAM_DIR.
FILES=(
    "vendor/ExhaustiveDeps.upstream.ts|src/rules/ExhaustiveDeps.ts|rules/ExhaustiveDeps.ts"
    "vendor/Utils.upstream.ts|src/shared/Utils.ts|shared/Utils.ts"
)

check_only=0
ref=main
while [ $# -gt 0 ]; do
    case "$1" in
        --check) check_only=1; shift ;;
        --ref) ref=$2; shift 2 ;;
        *) echo "unknown argument: $1" >&2; exit 3 ;;
    esac
done

pinned=$(cat vendor/UPSTREAM_REF)

# Resolving the ref to a commit keeps the pin reproducible after the branch moves on.
fetched_ref=$(curl -sSfL --retry 3 --retry-delay 2 --retry-all-errors -H 'Accept: application/vnd.github.sha' \
    "https://api.github.com/repos/$UPSTREAM_REPO/commits/$ref" 2>/dev/null) || {
    echo "cannot resolve $UPSTREAM_REPO@$ref" >&2
    exit 3
}

echo "pinned:  $pinned"
echo "fetched: $fetched_ref"

staging=$(mktemp -d)
trap 'rm -rf "$staging"' EXIT

drift=0
for entry in "${FILES[@]}"; do
    IFS='|' read -r pristine live upstream_path <<<"$entry"
    curl -sSfL --retry 3 --retry-delay 2 --retry-all-errors -o "$staging/$(basename "$pristine")" \
        "https://raw.githubusercontent.com/$UPSTREAM_REPO/$fetched_ref/$UPSTREAM_DIR/$upstream_path" || {
        echo "cannot fetch $upstream_path" >&2
        exit 3
    }
    if ! cmp -s "$pristine" "$staging/$(basename "$pristine")"; then
        drift=1
        echo "changed upstream: $upstream_path"
    fi
done

# The pin names the revision the pristine copies came from, so an unchanged upstream leaves it alone.
if [ "$drift" -eq 0 ]; then
    echo "no upstream drift"
    exit 0
fi

if [ "$check_only" -eq 1 ]; then
    exit 2
fi

conflicts=0
for entry in "${FILES[@]}"; do
    IFS='|' read -r pristine live _ <<<"$entry"
    incoming=$staging/$(basename "$pristine")

    # Local edits are "ours", the pinned copy is the base, so upstream hunks land only where nothing local sits.
    git merge-file -L local -L "pinned $pinned" -L "upstream $fetched_ref" \
        "$live" "$pristine" "$incoming"
    status=$?
    if [ "$status" -lt 0 ] || [ "$status" -gt 127 ]; then
        echo "merge failed for $live" >&2
        exit 3
    fi
    if [ "$status" -gt 0 ]; then
        conflicts=$((conflicts + status))
        echo "$live: $status conflict(s)"
    else
        echo "$live: merged clean"
    fi

    cp "$incoming" "$pristine"
done

printf '%s\n' "$fetched_ref" > vendor/UPSTREAM_REF

# The README names the pin, and CI refuses the two disagreeing.
"$repo_root/scripts/upstream-banner.sh" || echo "README banner not updated" >&2

if [ "$conflicts" -gt 0 ]; then
    echo "$conflicts conflict(s) left as markers in src/" >&2
    exit 1
fi
exit 0
