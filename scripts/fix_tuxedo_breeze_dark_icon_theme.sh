#!/usr/bin/env bash
#
# fix_tuxedo_breeze_dark_icon_theme.sh
#
# The TUXEDO Breeze Dark icon theme lists "places/symbolic" in its
# Directories= line but ships no [places/symbolic] section for it, so GTK logs:
#
#   Theme directory places/symbolic of theme tuxedo-breeze-dark has no size field
#
# and then drops the whole directory, making places/symbolic/crazy-tux-key.svg
# unresolvable by any icon lookup. This adds the missing section and rebuilds
# the icon cache.
#
# The index.theme is root-owned, so the script re-runs itself under sudo when it
# cannot write to the file. A tuxedo-breeze-dark package update will overwrite
# the change, so it is also worth reporting upstream.
#
# Usage: scripts/fix_tuxedo_breeze_dark_icon_theme.sh [THEME_DIR]
#
set -euo pipefail

THEME_DIR=${1:-/usr/share/icons/tuxedo-breeze-dark}
INDEX="$THEME_DIR/index.theme"
SECTION=places/symbolic

if [[ ! -f "$INDEX" ]]; then
  echo "error: $INDEX not found; theme not installed" >&2
  exit 1
fi

if grep -qF "[$SECTION]" "$INDEX"; then
  echo "already declared: [$SECTION] present in $INDEX"
  exit 0
fi

if ! grep '^Directories=' "$INDEX" | grep -qF "$SECTION"; then
  echo "warning: $SECTION is not listed in Directories=; nothing to declare" >&2
  exit 0
fi

if [[ ! -w "$INDEX" && $EUID -ne 0 ]]; then
  echo "root required to edit $INDEX; re-running under sudo"
  exec sudo -- "$(readlink -f "$0")" "$@"
fi

[[ -e "$INDEX.bak" ]] || cp "$INDEX" "$INDEX.bak"

printf '\n[%s]\nContext=Places\nSize=16\nMinSize=16\nMaxSize=512\nType=Scalable\n' \
  "$SECTION" >> "$INDEX"
echo "added [$SECTION] to $INDEX (backup: $INDEX.bak)"

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f -t "$THEME_DIR"
  echo "rebuilt icon cache for $THEME_DIR"
fi
