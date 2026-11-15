#!/usr/bin/env bash
# Install the one-at-a-time skill into OpenCode.
#
# Usage:
#   ./install.sh                  # global install (~/.config/opencode), symlinked
#   ./install.sh --project DIR    # project install (DIR/.opencode), symlinked
#   ./install.sh --enable DIR     # skill stays global; only add the trigger
#                                 # snippet to DIR's AGENTS.md (or CLAUDE.md)
#   ./install.sh --disable DIR    # remove the trigger snippet from DIR
#   ./install.sh --copy           # copy files instead of symlinking
#   ./install.sh --uninstall      # remove skill + snippet (global or --project)
#
# Typical setup: `./install.sh` once, then `./install.sh --enable ~/src/repo`
# in each repo where you want the skill to be used for sure.
#
# What a full install does:
#   1. Links/copies skills/one-at-a-time into <target>/skills/
#   2. Appends AGENTS.snippet.md to the rules file (once, marker-guarded)
#   3. Ensures opencode.json has the `question` permission set to allow
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ID="one-at-a-time"
SRC="$HERE/skills/$SKILL_ID"
SNIPPET="$HERE/AGENTS.snippet.md"
MARK_BEGIN="<!-- one-at-a-time:begin -->"
MARK_END="<!-- one-at-a-time:end -->"

MODE="link"
ACTION="install"   # install | uninstall | enable | disable
PROJECT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) PROJECT="${2:?--project needs a directory}"; shift 2 ;;
    --enable)  ACTION="enable";  PROJECT="${2:?--enable needs a directory}"; shift 2 ;;
    --disable) ACTION="disable"; PROJECT="${2:?--disable needs a directory}"; shift 2 ;;
    --copy) MODE="copy"; shift ;;
    --uninstall) ACTION="uninstall"; shift ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

log() { printf '%s\n' "$*"; }

# Pick the rules file for a project dir: AGENTS.md if present, else an
# existing CLAUDE.md (OpenCode reads it as a fallback and would ignore it if
# we created an AGENTS.md next to it), else a new AGENTS.md.
rules_file_for() {
  local dir="$1"
  if   [[ -f "$dir/AGENTS.md" ]]; then echo "$dir/AGENTS.md"
  elif [[ -f "$dir/CLAUDE.md" ]]; then echo "$dir/CLAUDE.md"
  else echo "$dir/AGENTS.md"; fi
}

add_snippet() {
  local f="$1"
  mkdir -p "$(dirname "$f")"; touch "$f"
  if grep -qF "$MARK_BEGIN" "$f"; then
    log "snippet already present in $f"
  else
    { [[ -s "$f" ]] && printf '\n'; printf '%s\n' "$MARK_BEGIN"; cat "$SNIPPET"; printf '%s\n' "$MARK_END"; } >> "$f"
    log "appended snippet to $f"
  fi
}

remove_snippet() {
  local f="$1"
  if [[ -f "$f" ]] && grep -qF "$MARK_BEGIN" "$f"; then
    local tmp; tmp="$(mktemp)"
    awk -v b="$MARK_BEGIN" -v e="$MARK_END" '
      $0==b {skip=1; next} $0==e {skip=0; next} !skip {print}
    ' "$f" > "$tmp"
    mv "$tmp" "$f"; log "removed snippet from $f"
  else
    log "no snippet in $f"
  fi
}

# ---------- enable / disable: rules file only ----------
if [[ "$ACTION" == "enable" || "$ACTION" == "disable" ]]; then
  PROJECT="$(cd "$PROJECT" && pwd)"
  RULES="$(rules_file_for "$PROJECT")"
  if [[ "$ACTION" == "enable" ]]; then
    add_snippet "$RULES"
    GLOBAL_DEST="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills/$SKILL_ID"
    if [[ ! -e "$GLOBAL_DEST/SKILL.md" && ! -e "$PROJECT/.opencode/skills/$SKILL_ID/SKILL.md" ]]; then
      log "note: skill not found globally or in this project; run ./install.sh first"
    fi
  else
    remove_snippet "$RULES"
  fi
  exit 0
fi

# ---------- resolve target for install / uninstall ----------
if [[ -n "$PROJECT" ]]; then
  PROJECT="$(cd "$PROJECT" && pwd)"
  TARGET="$PROJECT/.opencode"
  RULES="$(rules_file_for "$PROJECT")"
else
  TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
  RULES="$TARGET/AGENTS.md"
fi
SKILLS_DIR="$TARGET/skills"
DEST="$SKILLS_DIR/$SKILL_ID"
CONFIG="$TARGET/opencode.json"

# ---------- uninstall ----------
if [[ "$ACTION" == "uninstall" ]]; then
  if [[ -L "$DEST" || -d "$DEST" ]]; then
    rm -rf "$DEST"; log "removed $DEST"
  fi
  remove_snippet "$RULES"
  log "uninstalled. (opencode.json permission left as is.)"
  exit 0
fi

# ---------- 1. skill ----------
[[ -f "$SRC/SKILL.md" ]] || { echo "missing $SRC/SKILL.md" >&2; exit 1; }
mkdir -p "$SKILLS_DIR"
if [[ -e "$DEST" || -L "$DEST" ]]; then rm -rf "$DEST"; fi
if [[ "$MODE" == "link" ]]; then
  ln -s "$SRC" "$DEST"; log "linked  $DEST -> $SRC"
else
  cp -R "$SRC" "$DEST"; log "copied  $SRC -> $DEST"
fi

# ---------- 2. rules snippet ----------
add_snippet "$RULES"

# ---------- 3. question permission ----------
# OpenCode V2: "permissions": [ {action,resource,effect}, ... ]
# OpenCode V1: "permission":  { "question": "allow", ... }
# We detect which key the file already uses; a new file gets the V2 form.
PERM_RULE='{"action":"question","resource":"*","effect":"allow"}'
if [[ ! -f "$CONFIG" && -f "${CONFIG}c" ]]; then
  log "found ${CONFIG}c (jsonc); not touching it. Add manually:"
  log "  V2: \"permissions\": [ $PERM_RULE ]"
  log "  V1: \"permission\": { \"question\": \"allow\" }"
elif command -v jq >/dev/null 2>&1; then
  if [[ ! -f "$CONFIG" ]]; then
    printf '{\n  "$schema": "https://opencode.ai/config.json"\n}\n' > "$CONFIG"
  fi
  if ! jq -e . "$CONFIG" >/dev/null 2>&1; then
    log "WARNING: $CONFIG is not plain JSON (jsonc?); add manually:"
    log "  V2: \"permissions\": [ $PERM_RULE ]"
    log "  V1: \"permission\": { \"question\": \"allow\" }"
  elif jq -e '
       ((.permissions // []) | type=="array" and any(.[]; .action=="question"))
       or ((.permission // {}) | type=="object" and has("question"))
     ' "$CONFIG" >/dev/null; then
    log "question permission already configured in $CONFIG"
  else
    tmp="$(mktemp)"
    jq --argjson r "$PERM_RULE" '
      if has("permission") and (.permission|type)=="object" then
        .permission.question = "allow"                      # V1
      else
        .permissions = ((.permissions // []) + [$r])        # V2
      end
    ' "$CONFIG" > "$tmp" && mv "$tmp" "$CONFIG"
    log "added question=allow permission to $CONFIG"
  fi
else
  log "jq not found; add manually to $CONFIG:"
  log "  V2: \"permissions\": [ $PERM_RULE ]"
  log "  V1: \"permission\": { \"question\": \"allow\" }"
fi

log ""
log "done. In OpenCode, type @$SKILL_ID to load it manually, or just ask something that raises several questions."
[[ -z "$PROJECT" ]] && log "to make sure a given repo uses it: ./install.sh --enable /path/to/repo"
exit 0
