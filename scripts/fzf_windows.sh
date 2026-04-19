#!/usr/bin/env bash
# Outputs enriched window list for fzf popup, matching status bar naming.

ssh_icon='󰌘'
split_icon='⊟'
zoom_icon='󰊓'

tmux list-windows -F '#{window_index}|#{window_name}|#{pane_current_command}|#{pane_title}|#{window_panes}|#{window_zoomed_flag}' | \
while IFS='|' read -r index name command title panes zoomed; do

  # Resolve display name — mirror automatic-rename-format and window_status_format logic
  if [[ "$command" == "ssh" ]]; then
    # Extract hostname from pane_title (set by remote shell)
    host=$(echo "$title" | sed 's/^ssh //; s/ .*//; s/.*@//; s/:.*//')
    if echo "$host" | grep -qE '^[0-9.]+$|^[0-9]'; then host="$name"; fi
    label="${ssh_icon} ${host}"
  elif [[ "$title" =~ ^[a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+: ]]; then
    # oossh / remote bash — hostname from pane_title
    host=$(echo "$title" | sed 's/.*@//; s/:.*//')
    label="${ssh_icon} ${host}"
  else
    label="$name"
  fi

  # Add icon — zoom takes priority over split
  icon=""
  if [[ "$zoomed" == "1" ]]; then
    icon=" ${zoom_icon}"
  elif [[ "$panes" -gt 1 ]]; then
    icon=" ${split_icon}"
  fi

  # Display mirrors status bar: name│index [icon]
  printf '%s|%s│%s%s\n' "$index" "$label" "$index" "$icon"
done | fzf --reverse --cycle \
           --delimiter='|' \
           --with-nth=2 \
           --header='Jump to Window' | \
  cut -d'|' -f1 | xargs -I{} tmux select-window -t {}
