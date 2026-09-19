#!/usr/bin/env bash
# Rewrites the README badge naming the upstream commit the last check compared against.
# Usage: upstream-checked-badge.sh <commit sha>
# Exit 0 rewritten, 3 the badge block is missing or the argument is no commit sha.
set -uo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root" || exit 3

UPSTREAM_REPO=${UPSTREAM_REPO:-facebook/react}
START='<!-- checked:start -->'
END='<!-- checked:end -->'

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

if ! grep -qF "$START" README.md || ! grep -qF "$END" README.md; then
    echo "README carries no checked badge" >&2
    exit 3
fi

# Shields reads the label and the message out of the path, so a space goes in encoded.
badge="[![Upstream checked](https://img.shields.io/badge/upstream%20checked-${sha:0:8}-informational)](https://github.com/$UPSTREAM_REPO/commit/$sha)"
block=$(printf '%s\n%s\n%s\n' "$START" "$badge" "$END")

BLOCK="$block" START="$START" END="$END" node -e '
    const fs = require("fs");
    const { BLOCK, START, END } = process.env;
    const readme = fs.readFileSync("README.md", "utf8");
    const from = readme.indexOf(START);
    const to = readme.indexOf(END) + END.length;
    fs.writeFileSync("README.md", readme.slice(0, from) + BLOCK.trimEnd() + readme.slice(to));
' || exit 3

echo "README checked badge set to $sha"
