#!/usr/bin/env bash
# Outputs "program parent/filename" for editor windows.
# Usage: editor_title.sh <pane_title> <pane_current_path> [pane_pid] [pane_current_command]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

pane_title="$1"
cwd="$2"
pane_pid="${3:-}"
editor="${4:-vim}"

file=""

# Primary: read the file path from the editor's process arguments.
# This is reliable regardless of whether vim sets the terminal title.
if [ -n "$pane_pid" ]; then
  editor_pid=$(pgrep -P "$pane_pid" 2>/dev/null | head -1)
  if [ -n "$editor_pid" ]; then
    file=$(ps -p "$editor_pid" -o args= 2>/dev/null \
           | sed 's/^[^ ]* *//' \
           | tr ' ' '\n' \
           | grep -v '^-' \
           | grep -v '^$' \
           | tail -1)
    [ -n "$file" ] && [[ "$file" != /* ]] && file="$cwd/$file"
  fi
fi

# Fallback: parse pane_title (works when vim does set the title properly)
if [ -z "$file" ]; then
  title="$pane_title"

  # Strip hostname noise
  _hn=$(hostname -s 2>/dev/null)
  title="${title##${_hn}:}"
  title="${title%% @ ${_hn}}"
  title="${title%% - ${_hn}}"
  title="${title%% - ${_hn} *}"

  # Strip editor suffixes
  title="${title% - NVIM}"
  title="${title% - NeoVim}"
  title="${title% - VIM}"
  title="${title% - vim}"

  # Strip trailing (path) annotation
  title="${title% (*)}"
  title="${title%% (*}"

  title="${title#"${title%%[![:space:]]*}"}"  # trim leading space
  title="${title%"${title##*[![:space:]]}"}"  # trim trailing space

  if [ -n "$title" ] && [[ "$title" != "$(hostname -s 2>/dev/null)" ]]; then
    [[ "$title" != /* && "$title" != ~* ]] && title="$cwd/$title"
    file="$title"
  fi
fi

# Format: "editor parent/filename"
if [ -n "$file" ]; then
  parent=$(basename "$(dirname "$file")")
  filename=$(basename "$file")
  echo "${editor} ${parent}/${filename}"
else
  # Last resort: just show the editor and the cwd basename
  echo "${editor} $(basename "$cwd")"
fi
