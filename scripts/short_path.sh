#!/usr/bin/env bash
# Outputs a truncated path like /d/su/directory
# Usage: short_path.sh [pane_current_path]

path="${1:-$HOME}"
path="${path/#$HOME/~}"

IFS='/' read -ra parts <<< "$path"
result=""
last_index=$(( ${#parts[@]} - 1 ))

for i in "${!parts[@]}"; do
  part="${parts[$i]}"
  [ -z "$part" ] && continue
  if [ "$i" -eq "$last_index" ]; then
    result="${result}/${part}"
  else
    result="${result}/${part:0:1}"
  fi
done

echo "${result:-/}"
