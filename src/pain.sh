#!/usr/bin/env bash
#
# pain.sh: apply version-aware pane and window management bindings.
#
# Every binding is gated to the tmux versions TPM supports (1.9 and up): full
# splits need 2.3, the copy-mode-vi table needs 2.4, and binding notes need 3.1.
# Each key honors @pane_control_disabled_keys so a conflicting key can be turned
# off. With PAIN_DRY_RUN set, each tmux command is printed instead of run, which
# is how the test suite validates the binding matrix without a live tmux.

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
  local ver step npath synckey splitf
  ver="$(tmux_version)"
  step="$(get_opt @pane_resize 5)"
  synckey="$(get_opt @pane_control_sync_key S)"
  npath="$(get_opt @new_window_path true)"
  PAIN_DISABLED="$(get_opt @pane_control_disabled_keys "")"
  PAIN_NOTES=0
  version_ge "${ver}" 3.1 && PAIN_NOTES=1
  splitf=0
  version_ge "${ver}" 2.3 && splitf=1

  # Pane navigation, vim style. Not repeatable on purpose: a held key drifts.
  pain_bind "" h "Select pane left" select-pane -L
  pain_bind "" C-h "Select pane left" select-pane -L
  pain_bind "" j "Select pane below" select-pane -D
  pain_bind "" C-j "Select pane below" select-pane -D
  pain_bind "" k "Select pane above" select-pane -U
  pain_bind "" C-k "Select pane above" select-pane -U
  pain_bind "" l "Select pane right" select-pane -R
  pain_bind "" C-l "Select pane right" select-pane -R

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

  # New window in the current path, unless turned off.
  case "${npath}" in
    true|on|1) pain_bind "" c "New window here" new-window -c "${_path}" ;;
  esac

  # Move the current window left or right, keeping focus on it.
  pain_bind "-r" "<" "Swap window left" swap-window -d -t -1
  pain_bind "-r" ">" "Swap window right" swap-window -d -t +1

  # Toggle synchronized input across panes, with visible state. The separator is
  # an escaped \; so tmux keeps display-message inside the binding; a bare ; would
  # split it off and run the message on every config load.
  pain_bind "" "${synckey}" "Toggle pane sync" set-window-option synchronize-panes "\\;" display-message "synchronize-panes #{?synchronize-panes,on,off}"

  # Optional seamless vim navigation, off by default. Needs the copy-mode-vi
  # table, which is tmux 2.4 and up.
  if [[ "$(get_opt @pane_control_vim_navigation off)" == "on" ]] && version_ge "${ver}" 2.4; then
    _apply_vim_nav
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  apply_pain
fi
