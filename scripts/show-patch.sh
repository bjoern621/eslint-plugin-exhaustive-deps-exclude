#!/usr/bin/env bash
# Prints the local delta against the pinned upstream revision, as a unified diff.
# Usage: show-patch.sh [--stat]
set -uo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root" || exit 1

FILES=(
    "vendor/ExhaustiveDeps.upstream.ts|src/rules/ExhaustiveDeps.ts"
    "vendor/Utils.upstream.ts|src/shared/Utils.ts"
)

echo "pinned upstream: $(cat vendor/UPSTREAM_REF)"
echo

for entry in "${FILES[@]}"; do
    IFS='|' read -r pristine live <<<"$entry"
    if [ "${1:-}" = "--stat" ]; then
        printf '%s: %s changed line(s)\n' "$live" "$(diff -u "$pristine" "$live" | grep -c '^[+-][^+-]')"
    else
        diff -u --label "upstream/$(basename "$live")" --label "$live" "$pristine" "$live"
    fi
done
exit 0
