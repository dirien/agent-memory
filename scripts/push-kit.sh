#!/usr/bin/env bash
# push-kit.sh — validate and push kit/ to an OCI registry.
#
#   ./scripts/push-kit.sh                  # ghcr.io/dirien/agent-memory-kit:latest
#   TAG=v0.2.0 ./scripts/push-kit.sh       # a specific tag
#   REGISTRY=ghcr.io/you ./scripts/push-kit.sh
#
# Requires `sbx` and Docker logged in to the registry (.github/workflows/publish-kit.yaml
# does both). Consumers use the bare OCI reference:
#   sbx run --kit ghcr.io/dirien/infrastructure-kit:v0.10.5 --kit ghcr.io/dirien/agent-memory-kit:latest claude .
#
# Reproducibility: the staged spec.yaml's KIT_REF is rewritten to the exact commit
# being published, so the artifact always installs agent-memory from an
# immutable commit, never a moving branch.
set -euo pipefail

registry="${REGISTRY:-ghcr.io/dirien}"
name="${KIT_NAME:-agent-memory-kit}"
tag="${TAG:-latest}"
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
image="${registry}/${name}"

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
dest="$stage/$name"
mkdir -p "$dest"

cp -a "$repo_root/kit/." "$dest/"
[ -f "$repo_root/LICENSE" ] && cp -f "$repo_root/LICENSE" "$dest/LICENSE"

sha="$(git -C "$repo_root" rev-parse HEAD 2>/dev/null || true)"
if [ -n "$sha" ]; then
  perl -0pi -e 's/(KIT_REF=")[^"]*(")/${1}'"$sha"'${2}/' "$dest/spec.yaml"
  echo "pinned KIT_REF=${sha} in the published spec.yaml"
else
  echo "WARNING: not a git checkout; publishing with KIT_REF unchanged" >&2
fi

sbx kit validate "$dest"
sbx kit push "$dest" "${image}:${tag}"
echo "pushed ${image}:${tag}"
