#!/usr/bin/env bash
# Outputs the current session as "index.session_name".

current_session=$(tmux display-message -p '#S' 2>/dev/null)
sessions=$(tmux list-sessions -F '#{session_name}' 2>/dev/null)

index=0
i=0
while IFS= read -r session; do
  i=$((i + 1))
  if [ "$session" = "$current_session" ]; then
    index=$i
  fi
done <<< "$sessions"

printf '%s:%s' "$index" "$current_session"
