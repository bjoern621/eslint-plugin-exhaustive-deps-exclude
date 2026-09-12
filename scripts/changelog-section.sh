#!/usr/bin/env bash
# Prints the CHANGELOG entries for one version, without the heading.
# Usage: changelog-section.sh <version>
# Exit 1 when the version has no section, or the section carries nothing.
set -uo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root" || exit 1

version=${1:-}
if [ -z "$version" ]; then
    echo "usage: changelog-section.sh <version>" >&2
    exit 1
fi

section=$(awk -v want="## [$version]" '
    index($0, want) == 1 { taking = 1; next }
    taking && /^## / { exit }
    taking { print }
' CHANGELOG.md)

# Blank lines around the entries carry no information for a release body.
section=$(printf '%s\n' "$section" | sed -e '/./,$!d' | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}')

if [ -z "$section" ]; then
    echo "CHANGELOG.md holds no entries under ## [$version]" >&2
    exit 1
fi

printf '%s\n' "$section"
