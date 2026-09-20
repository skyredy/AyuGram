#!/bin/bash
# Import a Telegram-iOS release onto the local `upstream` vendor branch.
#
# The vendor branch carries one commit per upstream release: a plain snapshot of
# that release's tree, parented on the previous snapshot. Telegram-iOS's own
# history is never imported — a full clone is several gigabytes, and the only
# thing a merge needs is a common ancestor, which the previous snapshot already
# provides.
#
#   tools/ayg-upstream/import-release.sh 13.0
#
# Afterwards, merge it into the working branch:
#
#   git merge upstream        # base = the previous snapshot
#
# See docs/AYGUpstreamUpdate.md for the full procedure.

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "usage: $0 <version>      e.g. $0 13.0" >&2
    exit 2
fi

VERSION="$1"
TAG="release-$VERSION"
LOCAL_TAG="upstream-$VERSION"
REMOTE="${AYG_UPSTREAM_REMOTE:-upstream}"
REMOTE_URL="https://github.com/TelegramMessenger/Telegram-iOS.git"

cd "$(git rev-parse --show-toplevel)"

if ! git remote get-url "$REMOTE" >/dev/null 2>&1; then
    echo "adding remote '$REMOTE' -> $REMOTE_URL"
    git remote add "$REMOTE" "$REMOTE_URL"
fi

if ! git rev-parse --verify --quiet upstream >/dev/null; then
    echo "error: no 'upstream' branch. This repository has not been set up for" >&2
    echo "       vendor imports yet — see docs/AYGUpstreamUpdate.md." >&2
    exit 1
fi

# --depth=1: we want the tree, not the history.
echo "fetching $TAG ..."
git fetch --depth=1 --no-tags "$REMOTE" "refs/tags/$TAG:refs/tags/$LOCAL_TAG" --force

UPSTREAM_COMMIT=$(git rev-parse "$LOCAL_TAG^{commit}")
TREE=$(git rev-parse "$LOCAL_TAG^{tree}")
PARENT=$(git rev-parse upstream)

if [ "$TREE" = "$(git rev-parse 'upstream^{tree}')" ]; then
    echo "upstream branch already holds this exact tree — nothing to import."
    exit 0
fi

NEW=$(git commit-tree "$TREE" -p "$PARENT" -m "Telegram-iOS $TAG

Upstream snapshot. Upstream commit: $UPSTREAM_COMMIT (tag $TAG)")

git branch -f upstream "$NEW"

echo
echo "upstream: $(git rev-parse --short "$PARENT") -> $(git rev-parse --short "$NEW")  ($TAG)"
echo
echo "Upstream changed, relative to the previous snapshot:"
git diff --shortstat "$PARENT" "$NEW"
echo
echo "Files we patch that upstream also touched:"
git diff --name-only upstream "$(git rev-parse --abbrev-ref HEAD)" > /tmp/ayg-ours.$$ 2>/dev/null || true
git diff --name-only "$PARENT" "$NEW" | sort > /tmp/ayg-theirs.$$
sort /tmp/ayg-ours.$$ -o /tmp/ayg-ours.$$
comm -12 /tmp/ayg-ours.$$ /tmp/ayg-theirs.$$ | sed 's/^/  /'
rm -f /tmp/ayg-ours.$$ /tmp/ayg-theirs.$$
echo
echo "Next:  git merge upstream"
