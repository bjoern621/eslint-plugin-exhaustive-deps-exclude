#!/usr/bin/env bash
# Rewrites the README block naming the vendored upstream, from vendor/UPSTREAM_REF.
# Usage: upstream-banner.sh [--check]
# --check compares the commit named in the block against the pin and writes nothing.
# Exit 0 agreed or rewritten, 1 stale under --check, 3 the block is missing.
set -uo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root" || exit 3

UPSTREAM_PACKAGE=eslint-plugin-react-hooks
START='<!-- upstream:start -->'
END='<!-- upstream:end -->'

check_only=0
case "${1:-}" in
    --check) check_only=1 ;;
    "") ;;
    *) echo "unknown argument: $1" >&2; exit 3 ;;
esac

pinned=$(cat vendor/UPSTREAM_REF)

if ! grep -qF "$START" README.md || ! grep -qF "$END" README.md; then
    echo "README carries no upstream block" >&2
    exit 3
fi

if [ "$check_only" -eq 1 ]; then
    if grep -qF "$pinned" README.md; then
        exit 0
    fi
    echo "README names another commit than vendor/UPSTREAM_REF ($pinned)" >&2
    exit 1
fi

# The canary a commit was released as carries the short revision, so the registry answers which version the pin is.
short=${pinned:0:8}
version=$(npm view "$UPSTREAM_PACKAGE" versions --json 2>/dev/null |
    node -e '
        let raw = "";
        process.stdin.on("data", chunk => (raw += chunk));
        process.stdin.on("end", () => {
            const marker = `-canary-${process.argv[1]}-`;
            const hit = JSON.parse(raw || "[]").find(v => v.includes(marker));
            if (hit) process.stdout.write(hit);
        });
    ' "$short")

commit_url=https://github.com/facebook/react/commit/$pinned

if [ -n "$version" ]; then
    line="> **Based on** [\`$UPSTREAM_PACKAGE@$version\`](https://www.npmjs.com/package/$UPSTREAM_PACKAGE/v/$version)
> from React commit [\`$pinned\`]($commit_url)."
else
    # A commit outside the canary line has no version to name.
    line="> **Based on** \`$UPSTREAM_PACKAGE\` at React commit [\`$pinned\`]($commit_url)."
fi

block=$(printf '%s\n%s\n%s\n' "$START" "$line" "$END")

BLOCK="$block" START="$START" END="$END" node -e '
    const fs = require("fs");
    const { BLOCK, START, END } = process.env;
    const readme = fs.readFileSync("README.md", "utf8");
    const from = readme.indexOf(START);
    const to = readme.indexOf(END) + END.length;
    fs.writeFileSync("README.md", readme.slice(0, from) + BLOCK.trimEnd() + readme.slice(to));
' || exit 3

echo "README upstream block set to $pinned${version:+ ($version)}"
