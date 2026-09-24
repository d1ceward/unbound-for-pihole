#!/usr/bin/env bash
#
# Cut a new release: bump VERSION on develop, fast-forward master, tag it and
# publish a GitHub release. Pushing the tag triggers the Build workflow, which
# publishes the image to ghcr.io.
#
# Usage: scripts/release.sh [-n|--dry-run] <major|minor|patch|X.Y.Z>

set -euo pipefail

REMOTE="${REMOTE:-origin}"
DEVELOP_BRANCH="develop"
MAIN_BRANCH="master"
DRY_RUN=false

usage() {
  echo "Usage: $0 [-n|--dry-run] <major|minor|patch|X.Y.Z>" >&2
  exit 1
}

die() {
  echo "error: $*" >&2
  exit 1
}

run() {
  if $DRY_RUN; then
    echo "+ $*"
  else
    "$@"
  fi
}

bump=""
for arg in "$@"; do
  case "$arg" in
    -n|--dry-run) DRY_RUN=true ;;
    -h|--help) usage ;;
    *) [ -z "$bump" ] || usage; bump="$arg" ;;
  esac
done
[ -n "$bump" ] || usage

command -v gh >/dev/null || die "gh CLI is required"
cd "$(git rev-parse --show-toplevel)"

# Sanity checks on the working tree and branches
[ -z "$(git status --porcelain)" ] || die "working tree is not clean"
[ "$(git symbolic-ref --short HEAD)" = "$DEVELOP_BRANCH" ] || die "must be run from $DEVELOP_BRANCH"

git fetch --quiet --tags "$REMOTE"
[ "$(git rev-parse HEAD)" = "$(git rev-parse "$REMOTE/$DEVELOP_BRANCH")" ] \
  || die "$DEVELOP_BRANCH is not in sync with $REMOTE/$DEVELOP_BRANCH"
git merge-base --is-ancestor "$REMOTE/$MAIN_BRANCH" HEAD \
  || die "$MAIN_BRANCH cannot be fast-forwarded to $DEVELOP_BRANCH"

# The latest tag is the source of truth, VERSION may lag behind it
latest_tag="$(git tag --list 'v[0-9]*.[0-9]*.[0-9]*' --sort=-v:refname | head -n1)"
current="${latest_tag#v}"
current="${current:-0.0.0}"
IFS=. read -r major minor patch <<< "$current"

case "$bump" in
  major) version="$((major + 1)).0.0" ;;
  minor) version="$major.$((minor + 1)).0" ;;
  patch) version="$major.$minor.$((patch + 1))" ;;
  *)
    [[ "$bump" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || usage
    version="$bump"
    ;;
esac

tag="v$version"
git rev-parse -q --verify "refs/tags/$tag" >/dev/null && die "tag $tag already exists"
[ "$(printf '%s\n%s\n' "$current" "$version" | sort -V | tail -n1)" = "$version" ] \
  && [ "$current" != "$version" ] || die "$version is not greater than $current"

if [ "${version##*.}" != "0" ]; then
  title="Hotfix $tag"
else
  title="Release $tag"
fi

echo "Releasing $tag (previous: ${latest_tag:-none}) as \"$title\""
if ! $DRY_RUN; then
  read -r -p "Continue? [y/N] " answer
  [[ "$answer" =~ ^[Yy]$ ]] || die "aborted"
fi

# Bump VERSION on develop
if $DRY_RUN; then
  echo "+ echo $version > VERSION"
else
  echo "$version" > VERSION
fi
run git add VERSION
run git commit -m "bump version to $version"
run git push "$REMOTE" "$DEVELOP_BRANCH"

# Fast-forward master to develop and tag it
run git push "$REMOTE" "HEAD:refs/heads/$MAIN_BRANCH"
run git fetch --quiet "$REMOTE" "$MAIN_BRANCH:$MAIN_BRANCH"
run git tag -a "$tag" -m "$title"
run git push "$REMOTE" "$tag"

run gh release create "$tag" --title "$title" --generate-notes --verify-tag

echo "Done: $tag released, the Build workflow will publish the image."
