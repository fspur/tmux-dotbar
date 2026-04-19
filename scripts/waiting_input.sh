#!/usr/bin/env bash
# Outputs a non-empty string if the shell at pane_pid has any foreground child
# process running (command is active in this pane).

pane_pid=$1
[ -z "$pane_pid" ] && exit 0

# Any direct child means a foreground command is running
children=$(pgrep -P "$pane_pid" 2>/dev/null)
[ -n "$children" ] && printf "1"
