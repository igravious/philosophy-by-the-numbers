#!/usr/bin/env bash
#
# fix_zotero_white_loading_svg.sh
#
# Zotero ships CSS referencing a white-variant spinner that the build never
# packages. At startup Gecko logs:
#
#   Missing chrome or resource URL: chrome://zotero/skin/16/white/loading.svg
#
# The reference is a third background layer of .zotero-spinner-16 in
# chrome/content/zotero-platform/*/zotero.css, sized center/0, so it changes
# nothing visually -- but the asset is genuinely absent. This copies the
# light-variant icon into place inside app/omni.ja (at size 0 the contents are
# irrelevant) and verifies the archive afterwards.
#
# Zotero must be closed. A Zotero update will replace omni.ja, so this is a
# local patch, not a permanent fix.
#
# Usage: scripts/fix_zotero_white_loading_svg.sh [INSTALL_DIR | path/to/omni.ja]
#
set -euo pipefail

MISSING=chrome/skin/default/zotero/16/white/loading.svg
SOURCE=chrome/skin/default/zotero/16/light/loading.svg

for tool in unzip zip; do
  command -v "$tool" >/dev/null 2>&1 || { echo "error: $tool not found" >&2; exit 1; }
done

arg=${1:-}
if [[ -n "$arg" ]]; then
  if [[ -f "$arg" && $(basename "$arg") == omni.ja ]]; then
    OMNI=$arg
  elif [[ -f "$arg/app/omni.ja" ]]; then
    OMNI=$arg/app/omni.ja
  elif [[ -f "$arg/omni.ja" ]]; then
    OMNI=$arg/omni.ja
  else
    echo "error: no omni.ja found at $arg" >&2
    exit 1
  fi
else
  launcher=$(command -v zotero || true)
  if [[ -z "$launcher" ]]; then
    echo "error: zotero not on PATH; pass the install directory as an argument" >&2
    exit 1
  fi
  OMNI=$(dirname "$(readlink -f "$launcher")")/app/omni.ja
fi

OMNI=$(readlink -f "$OMNI") || { echo "error: cannot resolve $OMNI" >&2; exit 1; }
[[ -f "$OMNI" ]] || { echo "error: $OMNI not found" >&2; exit 1; }

if pgrep -x zotero-bin >/dev/null 2>&1 || pgrep -x zotero >/dev/null 2>&1; then
  echo "error: Zotero is running; close it first" >&2
  exit 1
fi

listing=$(unzip -Z1 "$OMNI")

if grep -qxF "$MISSING" <<<"$listing"; then
  echo "already present: $MISSING"
  exit 0
fi

if ! grep -qxF "$SOURCE" <<<"$listing"; then
  echo "error: $SOURCE not found in $OMNI; unexpected archive layout" >&2
  exit 1
fi

[[ -e "$OMNI.bak" ]] || cp "$OMNI" "$OMNI.bak"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/tree/$(dirname "$MISSING")"
unzip -p "$OMNI" "$SOURCE" > "$tmp/tree/$MISSING"
(cd "$tmp/tree" && zip -q "$OMNI" "$MISSING")

if unzip -t "$OMNI" >/dev/null 2>&1 && unzip -Z1 "$OMNI" | grep -qxF "$MISSING"; then
  echo "added $MISSING to $OMNI (backup: $OMNI.bak)"
else
  cp "$OMNI.bak" "$OMNI"
  echo "error: patch failed; archive restored from $OMNI.bak" >&2
  exit 1
fi
