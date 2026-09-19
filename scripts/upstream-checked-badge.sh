#!/usr/bin/env bash
# Rewrites the README badge naming the upstream commit the last check compared against.
# Usage: upstream-checked-badge.sh <commit sha> [<YYYY-MM-DD>] | --check
# The date defaults to today in UTC, and names the day the check ran.
# --check reports whether the block the sync workflow writes into is still there, and writes nothing.
# Exit 0 rewritten or present, 1 the block is missing under --check,
# 3 the block is missing while writing or the argument is no commit sha.
set -uo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root" || exit 3

UPSTREAM_REPO=${UPSTREAM_REPO:-facebook/react}
START='<!-- checked:start -->'
END='<!-- checked:end -->'

block_present() {
    grep -qF "$START" README.md && grep -qF "$END" README.md
}

if [ "${1:-}" = "--check" ]; then
    if block_present; then
        exit 0
    fi
    echo "README carries no checked badge, which the sync workflow writes into" >&2
    exit 1
fi

sha=${1:-}
case "$sha" in
    "" | *[!0-9a-f]*)
        echo "usage: upstream-checked-badge.sh <commit sha>" >&2
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

if ! block_present; then
    echo "README carries no checked badge" >&2
    exit 3
fi

# Shields reads the label and the message out of the path, so a space goes in encoded
# and a dash inside the message goes in doubled.
message="${sha:0:8}%20(${checked_on//-/--})"
badge="[![React upstream checked](https://img.shields.io/badge/React%20upstream%20checked-$message-informational \"React commit the copied rule was compared against, and the day of that check\")](https://github.com/$UPSTREAM_REPO/commit/$sha)"
# One line, so the badge sits beside the one ahead of it rather than under it.
block="$START$badge$END"

BLOCK="$block" START="$START" END="$END" node -e '
    const fs = require("fs");
    const { BLOCK, START, END } = process.env;
    const readme = fs.readFileSync("README.md", "utf8");
    const from = readme.indexOf(START);
    const to = readme.indexOf(END) + END.length;
    fs.writeFileSync("README.md", readme.slice(0, from) + BLOCK.trimEnd() + readme.slice(to));
' || exit 3

echo "README checked badge set to $sha, checked on $checked_on"
