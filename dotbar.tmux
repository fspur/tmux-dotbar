#!/usr/bin/env bash

get_tmux_option() {
  local option="$1"
  local default_value="$2"
  local option_value
  option_value=$(tmux show-options -gqv "$option")
  [ -n "$option_value" ] && echo "$option_value" || echo "$default_value"
}

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Colors ───────────────────────────────────────────────────────────────────
bg=$(get_tmux_option "@tmux-dotbar-bg"           'default')
fg=$(get_tmux_option "@tmux-dotbar-fg"           '#e1e1e1')
fg_current=$(get_tmux_option "@tmux-dotbar-fg-current"   '#7fb6fa')
fg_session=$(get_tmux_option "@tmux-dotbar-fg-session"   '#e1e1e1')
fg_arrow=$(get_tmux_option "@tmux-dotbar-fg-arrow"     '#88c0d0')
fg_split=$(get_tmux_option "@tmux-dotbar-fg-split"     '#88c0d0')
fg_maximized=$(get_tmux_option "@tmux-dotbar-fg-maximized" '#88c0d0')
fg_input=$(get_tmux_option "@tmux-dotbar-fg-input"     '#ebcb8b')
fg_bell=$(get_tmux_option "@tmux-dotbar-fg-bell"      '#ebcb8b')
fg_windows_activity=$(get_tmux_option "@tmux-dotbar-fg-windows-activity" '#8fbcbb')

# ─── Icons ────────────────────────────────────────────────────────────────────
right_arrow=$(get_tmux_option "@tmux-dotbar-prefix-arrow"       '❯')
left_arrow=$(get_tmux_option "@tmux-dotbar-prefix-arrow"        '❮')
split_pane_icon=$(get_tmux_option "@tmux-dotbar-split-icon"     '⊟')
maximized_pane_icon=$(get_tmux_option "@tmux-dotbar-maximized-icon" '󰊓')
input_icon=$(get_tmux_option "@tmux-dotbar-input-icon"          '•')
window_status_separator=$(get_tmux_option "@tmux-dotbar-window-status-separator" '⁞')
ssh_icon=$(get_tmux_option "@tmux-dotbar-ssh-icon"              '󰌘')

# ─── Options ──────────────────────────────────────────────────────────────────
status=$(get_tmux_option "@tmux-dotbar-position"          "bottom")
justify=$(get_tmux_option "@tmux-dotbar-justify"          "absolute-centre")
left_state=$(get_tmux_option "@tmux-dotbar-left"          true)
right_state=$(get_tmux_option "@tmux-dotbar-right"        false)
bold_status=$(get_tmux_option "@tmux-dotbar-bold-status"  false)
bold_current_window=$(get_tmux_option "@tmux-dotbar-bold-current-window" false)
show_maximized_icon_for_all_tabs=$(get_tmux_option "@tmux-dotbar-show-maximized-icon-for-all-tabs" false)
ssh_enabled=$(get_tmux_option "@tmux-dotbar-ssh-enabled"  true)
ssh_icon_only=$(get_tmux_option "@tmux-dotbar-ssh-icon-only" false)

# ─── Status bar text ──────────────────────────────────────────────────────────
session_text=$(get_tmux_option "@tmux-dotbar-session-text"       " #S ")
session_position=$(get_tmux_option "@tmux-dotbar-session-position" "left")
time_text=$(get_tmux_option "@tmux-dotbar-status-right-text"     " %H:%M ")

# ─── Status components ────────────────────────────────────────────────────────
session_component="#[bg=$bg,fg=$fg_session]${session_text}#{?client_prefix,#[fg=${fg_arrow}],#[fg=${fg}]}${right_arrow}#[bg=$bg,fg=${fg_session},bold]"
path_component="#[bg=$bg,fg=$fg_session] #($CURRENT_DIR/scripts/short_path.sh #{pane_current_path}) "
time_component="#[bg=$bg,fg=$fg_session]$time_text#[bg=$bg,fg=${fg_session}]"

# ─── Status left/right assembly ───────────────────────────────────────────────
if [ "$session_position" = "right" ]; then
  default_left=""
  [ "$right_state" = "true" ] && default_right="$time_component$path_component$session_component" || default_right="$path_component$session_component"
else
  default_left="$session_component"
  [ "$right_state" = "true" ] && default_right="$time_component$path_component" || default_right="$path_component"
fi
status_left=$(get_tmux_option "@tmux-dotbar-status-left"  "$default_left")
status_right=$(get_tmux_option "@tmux-dotbar-status-right" "$left_arrow$default_right")
[ "$left_state" != "true" ] && status_left=""

# ─── Window formats ───────────────────────────────────────────────────────────
base_window_format=$(get_tmux_option "@tmux-dotbar-window-status-format" \
  " #W│#I#{?#{>:#{window_panes},1}, #[fg=${fg_split}]${split_pane_icon}#[fg=${fg}],}#{?#{==:#{pane_current_command},bash},,#{?#{==:#{pane_current_command},zsh},,#[fg=${fg_input}]${input_icon}#[fg=${fg}]}}#{?window_bell_flag, #[fg=${fg_bell}]•#[fg=${fg}],}#{?window_activity_flag,#[fg=${fg_windows_activity}]${input_icon}#[fg=${fg}], } ")
base_window_format_current=" #W│#I#{?#{==:#{pane_current_command},bash},,#{?#{==:#{pane_current_command},zsh},,#[fg=${fg_input}]${input_icon}#[fg=${fg}]}}#{?window_zoomed_flag, #[fg=${fg_maximized}]${maximized_pane_icon},} "

# ─── SSH window formats ───────────────────────────────────────────────────────
if [ "$ssh_enabled" = true ]; then
  if [ "$ssh_icon_only" = true ]; then
    ssh_window_format=" ${ssh_icon}${base_window_format}"
    remote_window_format=" ${ssh_icon}${base_window_format}"
    ssh_window_format_current=" ${ssh_icon}${base_window_format_current}"
    remote_window_format_current=" ${ssh_icon}${base_window_format_current}"
  else
    ssh_window_format=" ${ssh_icon} #(host=\$(echo '#{pane_title}' | sed 's/^ssh //; s/ .*//; s/.*@//; s/:.*//'); if echo \"\$host\" | grep -qE '^[0-9.]+\$|^[0-9]'; then echo '#W'; else echo \"\$host\"; fi | cut -c1-20)│#I#{?#{>:#{window_panes},1}, #[fg=${fg_split}]${split_pane_icon}#[fg=${fg}],} "
    remote_window_format=" ${ssh_icon} #(echo '#{pane_title}' | sed 's/.*@//; s/:.*//' | cut -c1-20)│#I#{?#{>:#{window_panes},1}, #[fg=${fg_split}]${split_pane_icon}#[fg=${fg}],} "
    ssh_window_format_current=" ${ssh_icon} #(host=\$(echo '#{pane_title}' | sed 's/^ssh //; s/ .*//; s/.*@//; s/:.*//'); if echo \"\$host\" | grep -qE '^[0-9.]+\$|^[0-9]'; then echo '#W'; else echo \"\$host\"; fi | cut -c1-20)│#I#{?window_zoomed_flag, #[fg=${fg_maximized}]${maximized_pane_icon},} "
    remote_window_format_current=" ${ssh_icon} #(echo '#{pane_title}' | sed 's/.*@//; s/:.*//' | cut -c1-20)│#I#{?window_zoomed_flag, #[fg=${fg_maximized}]${maximized_pane_icon},} "
  fi
  window_status_format="#{?#{==:#{pane_current_command},ssh},${ssh_window_format},#{?#{m/r:^[a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+:,#{pane_title}},${remote_window_format},${base_window_format}}}"
  current_window_status_format="#{?#{==:#{pane_current_command},ssh},${ssh_window_format_current},#{?#{m/r:^[a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+:,#{pane_title}},${remote_window_format_current},${base_window_format_current}}}"
else
  window_status_format="${base_window_format}"
  current_window_status_format="${base_window_format_current}"
fi

# ─── Current window format ────────────────────────────────────────────────────
current_format="#[bg=${bg},fg=${fg_current}]${current_window_status_format}#[fg=${bg},bg=default]"
[ "$bold_current_window" = true ] && current_format="#[bg=${bg},fg=${fg_current},bold]${current_window_status_format}#[fg=${bg},bg=default]"

# ─── Apply to tmux ────────────────────────────────────────────────────────────
tmux set-option -g status-position          "$status"
tmux set-option -g status-justify           "$justify"
tmux set-option -g status-left              "$status_left"
tmux set-option -g status-right             "$status_right"
tmux set-option -g status-style             "bg=default,fg=${fg}$([ "$bold_status" = true ] && echo ',bold')"
tmux set-option -g status-interval          1

tmux set-window-option -g window-status-separator      "$window_status_separator"
tmux set-option -g window-status-style                 "bg=default,fg=${fg}"
tmux set-option -g window-status-format                "$window_status_format"
[ "$show_maximized_icon_for_all_tabs" = true ] && \
  tmux set-option -g window-status-format "${window_status_format}#{?window_zoomed_flag,${maximized_pane_icon},}"
tmux set-option -g window-status-current-format        "$current_format"
tmux set-option -g window-status-bell-style            "fg=${fg_bell},bg=default"
tmux set-option -g window-status-activity-style        "fg=${fg},bg=default"
tmux set-option -g monitor-activity                    on

tmux set-option -g automatic-rename on
tmux set-option -g automatic-rename-format '#{?#{==:#{pane_current_command},bash},#{?#{m/r:^[a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+:,#{pane_title}},#(echo "#{pane_title}" | sed "s/.*@//; s/:.*//" | cut -c1-20),#{b:pane_current_path}},#{?#{==:#{pane_current_command},zsh},#{b:pane_current_path},#{?#{==:#{pane_current_command},nvim},#('"$CURRENT_DIR"'/scripts/editor_title.sh "#{pane_title}" "#{pane_current_path}" "#{pane_pid}" "#{pane_current_command}"),#{?#{==:#{pane_current_command},vim},#('"$CURRENT_DIR"'/scripts/editor_title.sh "#{pane_title}" "#{pane_current_path}" "#{pane_pid}" "#{pane_current_command}"),#{pane_current_command}}}}}'

tmux set-option -g set-titles        on
tmux set-option -g set-titles-string '#{pane_title}'
