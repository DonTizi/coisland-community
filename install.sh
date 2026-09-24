#!/bin/sh
# Install CoIsland's agent skills into every agent skills folder found on this Mac:
#   Claude Code  ~/.claude/skills           (Cortex Code reads it too)
#   Codex        ~/.agents/skills
#   Cortex Code  ~/.snowflake/cortex/skills (or $SNOWFLAKE_HOME/cortex/skills), only when
#                ~/.claude/skills does not already have the skills
#
# From a clone:  sh install.sh [--dry-run] [--uninstall]
# Piped:         curl -fsSL https://raw.githubusercontent.com/DonTizi/coisland-community/main/install.sh | sh
#                curl -fsSL .../install.sh | sh -s -- --uninstall
#
# It copies folders and prints what it did. It reads no token and changes nothing else.
# Running it again updates the skills in place.

set -eu

REPO_TARBALL="${COISLAND_SKILLS_URL:-https://github.com/DonTizi/coisland-community/archive/refs/heads/main.tar.gz}"
SKILLS="coisland-monitors coisland-alerts"

DRY_RUN=0
UNINSTALL=0

usage() {
    cat <<'EOF'
usage: install.sh [--dry-run] [--uninstall]

  (no flag)     copy the CoIsland skills into every agent skills folder found
  --dry-run     print what would be done, change nothing
  --uninstall   remove the CoIsland skills from every agent skills folder
  -h, --help    show this help
EOF
}

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        --uninstall) UNINSTALL=1 ;;
        -h | --help) usage; exit 0 ;;
        *) printf 'install.sh: unknown option %s\n' "$arg" >&2; usage >&2; exit 64 ;;
    esac
done

if [ -z "${HOME:-}" ] || [ ! -d "$HOME" ]; then
    printf 'install.sh: HOME is not set to a folder.\n' >&2
    exit 1
fi

CLAUDE_DIR="$HOME/.claude/skills"
CODEX_DIR="$HOME/.agents/skills"
CORTEX_DIR="${SNOWFLAKE_HOME:-$HOME/.snowflake}/cortex/skills"

# ~ in what is printed, so the output reads like the README.
show() {
    case "$1" in
        "$HOME"/*) printf '%s/%s' '~' "${1#"$HOME"/}" ;;
        *) printf '%s' "$1" ;;
    esac
}

# Run a command, or only say it in a dry run.
act() {
    if [ "$DRY_RUN" -eq 0 ]; then
        "$@"
    fi
}

verb() {
    if [ "$DRY_RUN" -eq 1 ]; then printf 'would %s' "$1"; else printf '%s' "$2"; fi
}

has_all_skills() {
    for skill in $SKILLS; do
        [ -f "$1/$skill/SKILL.md" ] || return 1
    done
    return 0
}

# --- uninstall ------------------------------------------------------------

if [ "$UNINSTALL" -eq 1 ]; then
    removed=0
    for dir in "$CLAUDE_DIR" "$CODEX_DIR" "$CORTEX_DIR"; do
        for skill in $SKILLS; do
            if [ -d "$dir/$skill" ]; then
                act rm -rf "$dir/$skill"
                printf '%-14s %s\n' "$(verb remove removed)" "$(show "$dir/$skill")"
                removed=$((removed + 1))
            fi
        done
    done
    if [ "$removed" -eq 0 ]; then
        printf 'No CoIsland skills are installed; nothing to remove.\n'
    fi
    exit 0
fi

# --- where the skills come from --------------------------------------------

SOURCE=""
TMP=""
cleanup() {
    if [ -n "$TMP" ]; then rm -rf "$TMP"; fi
}
trap cleanup EXIT
trap 'exit 130' INT TERM

# Run from a clone: the skills sit next to this script.
case "$0" in
    */install.sh | install.sh)
        here=$(cd "$(dirname "$0")" && pwd)
        if has_all_skills "$here/skills"; then SOURCE="$here/skills"; fi
        ;;
esac

if [ -z "$SOURCE" ]; then
    if ! command -v curl >/dev/null 2>&1 || ! command -v tar >/dev/null 2>&1; then
        printf 'install.sh: curl and tar are needed to download the skills.\n' >&2
        exit 1
    fi
    TMP=$(mktemp -d "${TMPDIR:-/tmp}/coisland-skills.XXXXXX")
    printf 'Downloading %s\n' "$REPO_TARBALL"
    if ! curl -fsSL "$REPO_TARBALL" -o "$TMP/skills.tar.gz"; then
        printf 'install.sh: could not download %s\n' "$REPO_TARBALL" >&2
        exit 1
    fi
    tar -xzf "$TMP/skills.tar.gz" -C "$TMP"
    for dir in "$TMP"/*/; do
        if has_all_skills "${dir}skills"; then SOURCE="${dir%/}/skills"; fi
    done
    if [ -z "$SOURCE" ]; then
        printf 'install.sh: the download has no skills folder.\n' >&2
        exit 1
    fi
else
    printf 'Skills from %s\n' "$(show "$SOURCE")"
fi

# --- install ----------------------------------------------------------------

# Copy each skill into one agent folder: installed, updated or unchanged.
install_into() {
    agent=$1
    dir=$2
    printf '%s: %s\n' "$agent" "$(show "$dir")"
    act mkdir -p "$dir"
    for skill in $SKILLS; do
        target="$dir/$skill"
        if [ -d "$target" ] && diff -r "$SOURCE/$skill" "$target" >/dev/null 2>&1; then
            printf '  %-16s %s\n' unchanged "$skill"
            continue
        fi
        if [ -d "$target" ]; then state=$(verb update updated); else state=$(verb install installed); fi
        act rm -rf "$target"
        act cp -R "$SOURCE/$skill" "$target"
        printf '  %-16s %s\n' "$state" "$skill"
    done
}

found=0
claude_has=0

if [ -d "$HOME/.claude" ]; then
    install_into "Claude Code" "$CLAUDE_DIR"
    found=1
    claude_has=1
fi

if [ -d "$HOME/.agents" ] || [ -d "$HOME/.codex" ]; then
    install_into "Codex" "$CODEX_DIR"
    found=1
fi

if [ -d "$(dirname "$CORTEX_DIR")" ]; then
    found=1
    if [ "$claude_has" -eq 1 ]; then
        printf 'Cortex Code: skipped, it already reads %s\n' "$(show "$CLAUDE_DIR")"
        for skill in $SKILLS; do
            if [ -d "$CORTEX_DIR/$skill" ]; then
                printf '  note: %s also has %s, so Cortex Code sees it twice; remove one copy\n' \
                    "$(show "$CORTEX_DIR")" "$skill"
            fi
        done
    else
        install_into "Cortex Code" "$CORTEX_DIR"
    fi
fi

if [ "$found" -eq 0 ]; then
    printf 'No agent skills folder found (Claude Code, Codex or Cortex Code).\n'
    printf 'Copy the folders in skills/ into your agent'\''s skills folder by hand.\n'
    exit 1
fi

if [ "$DRY_RUN" -eq 1 ]; then
    printf 'Dry run: nothing was changed.\n'
else
    printf 'Done. Start a new agent session to load the skills.\n'
fi
