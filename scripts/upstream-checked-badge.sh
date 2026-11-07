#!/usr/bin/env bash
# Publishes the file the README badge reads, naming the upstream commit a check compared against.
# Usage: upstream-checked-badge.sh <commit sha> [<YYYY-MM-DD>] | --check
# The date defaults to today in UTC, and names the day the check ran.
# The file sits alone on its own branch, since the ruleset on the default branch refuses the workflow's push.
# --check reports whether the README badge still reads the file from that branch.
# Exit 0 published or agreed, 1 disagreed under --check, 2 the push failed, 3 the argument is no commit sha or no date.
set -uo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root" || exit 3

UPSTREAM_REPO=${UPSTREAM_REPO:-facebook/react}
DATA_BRANCH=badge-data
DATA_FILE=upstream-checked.json

if [ "${1:-}" = "--check" ]; then
    # The badge URL carries the path encoded.
    if ! grep -qF "%2F$DATA_BRANCH%2F$DATA_FILE" README.md; then
        echo "README carries no badge reading $DATA_FILE from $DATA_BRANCH" >&2
        exit 1
    fi
    exit 0
fi

sha=${1:-}
case "$sha" in
    "" | *[!0-9a-f]*)
        echo "usage: upstream-checked-badge.sh <commit sha> [<YYYY-MM-DD>]" >&2
        exit 3
        ;;
esac
if [ ${#sha} -lt 7 ]; then
    echo "commit sha too short: $sha" >&2
    exit 3
fi

checked_on=${2:-$(date -u +%F)}
case "$checked_on" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
    *)
        echo "date is not YYYY-MM-DD: $checked_on" >&2
        exit 3
        ;;
esac

# Shields reads one field per badge. The rendered text is assembled here rather than there.
blob=$(git hash-object -w --stdin <<JSON
{
    "sha": "$sha",
    "checked": "$checked_on",
    "message": "${sha:0:8} ($checked_on)",
    "commit": "https://github.com/$UPSTREAM_REPO/commit/$sha"
}
JSON
) || exit 2
tree=$(printf '100644 blob %s\t%s\n' "$blob" "$DATA_FILE" | git mktree) || exit 2

# Built from objects, so the caller's checkout and branch stay as they were.
# A missing branch starts without a parent. Every later check lands on top, so the branch log lists them all.
parent=()
if git fetch -q origin "$DATA_BRANCH" 2>/dev/null; then
    parent=(-p FETCH_HEAD)
fi
commit=$(git commit-tree "$tree" "${parent[@]}" -m "Record the upstream check against ${sha:0:12}") || exit 2

if ! git push -q origin "$commit:refs/heads/$DATA_BRANCH"; then
    echo "cannot push $DATA_BRANCH" >&2
    exit 2
fi

echo "$DATA_BRANCH set to $sha, checked on $checked_on"
