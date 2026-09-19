#!/usr/bin/env bash
# Writes the file the README badge reads, naming the upstream commit a check compared against.
# Usage: upstream-checked-badge.sh <commit sha> [<YYYY-MM-DD>] | --check
# The date defaults to today in UTC, and names the day the check ran.
# --check reports whether the file and the README badge still agree on where the data sits.
# Exit 0 written or agreed, 1 disagreed under --check, 3 the argument is no commit sha or no date.
set -uo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root" || exit 3

UPSTREAM_REPO=${UPSTREAM_REPO:-facebook/react}
DATA_FILE=vendor/upstream-checked.json

if [ "${1:-}" = "--check" ]; then
    status=0
    # The badge URL carries the path encoded. The file name is what both spellings share.
    if ! grep -qF "$(basename "$DATA_FILE")" README.md; then
        echo "README carries no badge reading $DATA_FILE" >&2
        status=1
    fi
    # The node program is quoted against the shell, taking the file as an argument instead.
    # shellcheck disable=SC2016
    if ! node -e '
        const data = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
        for (const key of ["sha", "checked", "message"]) {
            if (typeof data[key] !== "string" || data[key] === "") {
                throw new Error(`${process.argv[1]} carries no ${key}`);
            }
        }
    ' "$DATA_FILE"; then
        status=1
    fi
    exit "$status"
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
cat > "$DATA_FILE" <<JSON
{
    "sha": "$sha",
    "checked": "$checked_on",
    "message": "${sha:0:8} ($checked_on)",
    "commit": "https://github.com/$UPSTREAM_REPO/commit/$sha"
}
JSON

echo "$DATA_FILE set to $sha, checked on $checked_on"
