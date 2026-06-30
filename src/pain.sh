#!/usr/bin/env bash
#
# pain.sh: apply version-aware pane and window management bindings.
#
# Every binding is gated to the tmux versions TPM supports (1.9 and up): full
# splits need 2.3, the copy-mode-vi table needs 2.4, marked panes need 2.1,
# pane titles need 2.6, the top-left target token needs 3.0, and the scratch
# popup needs 3.2. Each key honors @pane_control_disabled_keys so a conflicting
# key can be turned off. With PAIN_DRY_RUN set, each tmux command is printed
# instead of run, which is how the test suite validates the binding matrix
# without a live tmux.

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/pain/pain.sh"

_emit() {
  if [[ -n "${PAIN_DRY_RUN:-}" ]]; then
    echo "$*"
  else
    tmux "$@"
  fi
}

# get_opt OPT DEFAULT -> the global option value, or DEFAULT when unset.
get_opt() {
  local v
  v="$(tmux show-option -gqv "${1}" 2>/dev/null)"
  echo "${v:-${2}}"
}

# pain_bind FLAGS KEY DESC CMD... -> bind KEY to CMD, skipping disabled keys and
# adding a description note when the tmux version supports it.
pain_bind() {
  local flags="${1}" key="${2}" desc="${3}"
  shift 3
  key_disabled "${key}" "${PAIN_DISABLED}" && return 0
  if [[ "${PAIN_NOTES}" == "1" ]]; then
    # shellcheck disable=SC2086
    _emit bind-key ${flags} -N "${desc}" "${key}" "$@"
  else
    # shellcheck disable=SC2086
    _emit bind-key ${flags} "${key}" "$@"
  fi
}

_path='#{pane_current_path}'

# _bind_nav KEY DESC EDGE DIRFLAG -> bind a pane-selection key. When no-wrap is
# active it guards the move with the edge flag so a selection never wraps around
# to the far side; otherwise it is a plain select-pane.
_bind_nav() {
  local key="${1}" desc="${2}" edge="${3}" dirflag="${4}"
  if [[ "${PAIN_NOWRAP}" == "1" ]]; then
    pain_bind "" "${key}" "${desc}" if-shell -F "#{${edge}}" "select-pane" "select-pane ${dirflag}"
  else
    pain_bind "" "${key}" "${desc}" select-pane "${dirflag}"
  fi
}

# _apply_vim_nav -> optional seamless Ctrl+h/j/k/l that moves the vim split when a
# vim family program runs in the pane, else the tmux pane. Mirrors the
# vim-tmux-navigator guard so the two interoperate.
_apply_vim_nav() {
  local is_vim pattern
  # The process pattern that marks a pane as running vim. Overridable so a
  # wrapped or renamed editor still hands off, matching vim-tmux-navigator.
  pattern="$(get_opt @pane_control_vim_pattern '(\\S+/)?g?\\.?(view|l?n?vim?x?|fzf)(diff)?(-wrapped)?')"
  is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +${pattern}\$'"
  _emit bind-key -n C-h if-shell "${is_vim}" "send-keys C-h" "select-pane -L"
  _emit bind-key -n C-j if-shell "${is_vim}" "send-keys C-j" "select-pane -D"
  _emit bind-key -n C-k if-shell "${is_vim}" "send-keys C-k" "select-pane -U"
  _emit bind-key -n C-l if-shell "${is_vim}" "send-keys C-l" "select-pane -R"
  _emit bind-key -n 'C-\' if-shell "${is_vim}" 'send-keys C-\\' 'select-pane -l'
  _emit bind-key -T copy-mode-vi C-h select-pane -L
  _emit bind-key -T copy-mode-vi C-j select-pane -D
  _emit bind-key -T copy-mode-vi C-k select-pane -U
  _emit bind-key -T copy-mode-vi C-l select-pane -R
  _emit bind-key -T copy-mode-vi 'C-\' select-pane -l
}

apply_pain() {
  local ver step npath synckey splitf vmark scratchcmd
  ver="$(tmux_version)"
  step="$(get_opt @pane_resize 5)"
  synckey="$(get_opt @pane_control_sync_key S)"
  npath="$(get_opt @new_window_path true)"
  PAIN_DISABLED="$(get_opt @pane_control_disabled_keys "")"
  PAIN_NOTES=0
  version_ge "${ver}" 3.1 && PAIN_NOTES=1
  splitf=0
  version_ge "${ver}" 2.3 && splitf=1
  vmark=0
  version_ge "${ver}" 2.1 && vmark=1

  # No-wrap pane selection needs the pane_at_* flags, which arrived in 2.6.
  PAIN_NOWRAP=0
  if [[ "$(get_opt @pane_control_no_wrap off)" == "on" ]] && version_ge "${ver}" 2.6; then
    PAIN_NOWRAP=1
  fi

  # Pane navigation, vim style. Not repeatable on purpose: a held key drifts.
  _bind_nav h "Select pane left" pane_at_left -L
  _bind_nav C-h "Select pane left" pane_at_left -L
  _bind_nav j "Select pane below" pane_at_bottom -D
  _bind_nav C-j "Select pane below" pane_at_bottom -D
  _bind_nav k "Select pane above" pane_at_top -U
  _bind_nav C-k "Select pane above" pane_at_top -U
  _bind_nav l "Select pane right" pane_at_right -R
  _bind_nav C-l "Select pane right" pane_at_right -R

  # Pane resizing, repeatable, step configurable.
  pain_bind "-r" H "Resize pane left" resize-pane -L "${step}"
  pain_bind "-r" J "Resize pane down" resize-pane -D "${step}"
  pain_bind "-r" K "Resize pane up" resize-pane -U "${step}"
  pain_bind "-r" L "Resize pane right" resize-pane -R "${step}"

  # Splits that keep the current directory, including the default keys.
  pain_bind "" "|" "Split right" split-window -h -c "${_path}"
  pain_bind "" "-" "Split down" split-window -v -c "${_path}"
  pain_bind "" '"' "Split down" split-window -v -c "${_path}"
  pain_bind "" "%" "Split right" split-window -h -c "${_path}"
  if [[ "${splitf}" -eq 1 ]]; then
    pain_bind "" "\\" "Split full width" split-window -fh -c "${_path}"
    pain_bind "" "_" "Split full height" split-window -fv -c "${_path}"
  else
    pain_bind "" "\\" "Split right" split-window -h -c "${_path}"
    pain_bind "" "_" "Split down" split-window -v -c "${_path}"
  fi

  # Smart split along the longer axis, keeping the path. A wider-than-tall pane
  # splits side by side; a taller-than-wide pane splits top and bottom. tmux
  # expands the pane dimensions before running the shell test.
  pain_bind "" "$(get_opt @pane_control_smart_split_key '*')" "Smart split" \
    if-shell "[ #{pane_width} -gt #{pane_height} ]" \
    "split-window -h -c ${_path}" "split-window -v -c ${_path}"

  # New window in the current path, unless turned off.
  case "${npath}" in
    true|on|1) pain_bind "" c "New window here" new-window -c "${_path}" ;;
  esac

  # Move the current window left or right, keeping focus on it.
  pain_bind "-r" "<" "Swap window left" swap-window -d -t -1
  pain_bind "-r" ">" "Swap window right" swap-window -d -t +1

  # Move the current window into another session by name.
  pain_bind "" "$(get_opt @pane_control_move_window_key '.')" "Move window to session" \
    command-prompt -p "move window to session:" "move-window -t '%%'"

  # Confirm before killing the window.
  pain_bind "" "$(get_opt @pane_control_kill_window_key '&')" "Kill window" \
    confirm-before -p "kill-window #W? (y/n)" kill-window

  # Pull a pane in from another window, or push the current pane out to its own.
  pain_bind "" "$(get_opt @pane_control_join_key '@')" "Join pane" \
    command-prompt -p "join pane from:" "join-pane -h -s '%%'"
  pain_bind "" "$(get_opt @pane_control_break_key '!')" "Break pane to window" break-pane

  # Swap the current pane with the previous or next, repeatable, and promote it
  # to the main slot. The top-left target token is 3.0 and up; older tmux uses
  # pane index 0.
  pain_bind "-r" "$(get_opt @pane_control_swap_prev_key '{')" "Swap pane up" swap-pane -U
  pain_bind "-r" "$(get_opt @pane_control_swap_next_key '}')" "Swap pane down" swap-pane -D
  if version_ge "${ver}" 3.0; then
    pain_bind "" "$(get_opt @pane_control_promote_key '+')" "Promote pane to main" \
      swap-pane -d -t '{top-left}'
  else
    pain_bind "" "$(get_opt @pane_control_promote_key '+')" "Promote pane to main" \
      swap-pane -d -t 0
  fi

  # Marked-pane swap workflow: mark a pane, move on, then swap the current pane
  # with the marked one. Marking needs 2.1.
  if [[ "${vmark}" -eq 1 ]]; then
    pain_bind "" "$(get_opt @pane_control_mark_key m)" "Mark pane" select-pane -m
    pain_bind "" "$(get_opt @pane_control_swap_mark_key '=')" "Swap with marked pane" swap-pane
  fi

  # Layout presets.
  pain_bind "" "$(get_opt @pane_control_layout_even_h_key E)" "Even-horizontal layout" \
    select-layout even-horizontal
  pain_bind "" "$(get_opt @pane_control_layout_even_v_key V)" "Even-vertical layout" \
    select-layout even-vertical
  pain_bind "" "$(get_opt @pane_control_layout_main_v_key B)" "Main-vertical layout" \
    select-layout main-vertical

  # Respawn the current pane, confirming first since it kills the running process.
  pain_bind "" "$(get_opt @pane_control_respawn_key R)" "Respawn pane" \
    confirm-before -p "respawn-pane? (y/n)" "respawn-pane -k"

  # Capture the whole scrollback to a file, prompting for the path.
  pain_bind "" "$(get_opt @pane_control_capture_key C)" "Capture scrollback to file" \
    command-prompt -p "save scrollback to:" -I "${HOME}/tmux-scrollback.log" \
    "capture-pane -S - ; save-buffer '%%' ; delete-buffer"

  # Name the current pane from a prompt. Pane titles arrived in 2.6.
  if version_ge "${ver}" 2.6; then
    pain_bind "" "$(get_opt @pane_control_pane_name_key P)" "Name pane" \
      command-prompt -p "pane title:" "select-pane -T '%%'"
  fi

  # Show pane titles in the border, opt-in. pane-border-status is 2.3 and up.
  if [[ "$(get_opt @pane_control_pane_titles off)" == "on" ]] && version_ge "${ver}" 2.3; then
    _emit set-option -g pane-border-status top
    _emit set-option -g pane-border-format " #{pane_index}: #{pane_title} "
  fi

  # Ephemeral scratch shell floating over the session. display-popup is 3.2+.
  if version_ge "${ver}" 3.2; then
    scratchcmd="$(get_opt @pane_control_scratch_command "")"
    if [[ -n "${scratchcmd}" ]]; then
      pain_bind "" "$(get_opt @pane_control_scratch_key g)" "Scratch popup" \
        display-popup -E -d "${_path}" -w 80% -h 80% "${scratchcmd}"
    else
      pain_bind "" "$(get_opt @pane_control_scratch_key g)" "Scratch popup" \
        display-popup -E -d "${_path}" -w 80% -h 80%
    fi
  fi

  # Toggle synchronized input across panes, with visible state. The separator is
  # an escaped \; so tmux keeps display-message inside the binding; a bare ; would
  # split it off and run the message on every config load.
  pain_bind "" "${synckey}" "Toggle pane sync" set-window-option synchronize-panes "\;" display-message "synchronize-panes #{?synchronize-panes,on,off}"

  # Optional seamless vim navigation, off by default. Needs the copy-mode-vi
  # table, which is tmux 2.4 and up.
  if [[ "$(get_opt @pane_control_vim_navigation off)" == "on" ]] && version_ge "${ver}" 2.4; then
    _apply_vim_nav
    # The prefixless C-l now navigates, so restore a shell clear-screen on the
    # prefixed C-l, overriding the pane-right bind above (last bind wins).
    pain_bind "" C-l "Clear screen" send-keys C-l
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  apply_pain
fi
