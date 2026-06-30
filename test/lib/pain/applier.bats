#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _PAIN_REVAMPED_LOADED
  export PAIN_DRY_RUN=1
  source "${BATS_TEST_DIRNAME}/../../../src/pain.sh"
  _tmux_version_string() { echo "tmux 3.5"; }
}

teardown() {
  cleanup_test_environment
}

@test "applier - functions are defined" {
  function_exists apply_pain
  function_exists pain_bind
  function_exists _apply_vim_nav
  function_exists get_opt
}

@test "applier - binds vim-style pane navigation" {
  run apply_pain
  [[ "${output}" == *"h select-pane -L"* ]]
  [[ "${output}" == *"C-h select-pane -L"* ]]
  [[ "${output}" == *"j select-pane -D"* ]]
  [[ "${output}" == *"k select-pane -U"* ]]
  [[ "${output}" == *"l select-pane -R"* ]]
}

@test "applier - resize bindings are repeatable and use the step" {
  run apply_pain
  [[ "${output}" == *"bind-key -r -N Resize pane left H resize-pane -L 5"* ]]
}

@test "applier - resize step is configurable" {
  tmux set-option -gq "@pane_resize" "10"
  run apply_pain
  [[ "${output}" == *"resize-pane -L 10"* ]]
  [[ "${output}" != *"resize-pane -L 5"* ]]
}

@test "applier - splits keep the current path including default keys" {
  run apply_pain
  [[ "${output}" == *"split-window -h -c #{pane_current_path}"* ]]
  [[ "${output}" == *"split-window -v -c #{pane_current_path}"* ]]
}

@test "applier - full splits use -f on tmux 2.3 and up" {
  run apply_pain
  [[ "${output}" == *"split-window -fh -c #{pane_current_path}"* ]]
  [[ "${output}" == *"split-window -fv -c #{pane_current_path}"* ]]
}

@test "applier - full splits fall back below tmux 2.3" {
  _tmux_version_string() { echo "tmux 2.2"; }
  run apply_pain
  [[ "${output}" != *"-fh"* ]]
  [[ "${output}" != *"-fv"* ]]
}

@test "applier - new window keeps the path and can be turned off" {
  run apply_pain
  [[ "${output}" == *"new-window -c #{pane_current_path}"* ]]
  tmux set-option -gq "@new_window_path" "false"
  run apply_pain
  [[ "${output}" != *"new-window"* ]]
}

@test "applier - window swap keeps focus with -d" {
  run apply_pain
  [[ "${output}" == *"swap-window -d -t -1"* ]]
  [[ "${output}" == *"swap-window -d -t +1"* ]]
}

@test "applier - synchronize toggle keeps display-message in the binding via an escaped separator" {
  run apply_pain
  [[ "${output}" == *'S set-window-option synchronize-panes \; display-message'* ]]
  [[ "${output}" != *'synchronize-panes ; display-message'* ]]
  tmux set-option -gq "@pane_control_sync_key" "Y"
  run apply_pain
  [[ "${output}" == *'Y set-window-option synchronize-panes \; display-message'* ]]
}

@test "applier - binding notes are added only on tmux 3.1 and up" {
  run apply_pain
  [[ "${output}" == *"bind-key -N Select pane left h"* ]]
  _tmux_version_string() { echo "tmux 2.6"; }
  run apply_pain
  [[ "${output}" == *"bind-key h select-pane -L"* ]]
  [[ "${output}" != *" -N "* ]]
}

@test "applier - disabled keys are skipped" {
  tmux set-option -gq "@pane_control_disabled_keys" "c <"
  run apply_pain
  [[ "${output}" != *"new-window"* ]]
  [[ "${output}" != *"swap-window -d -t -1"* ]]
  [[ "${output}" == *"swap-window -d -t +1"* ]]
}

@test "applier - smart vim navigation is off by default" {
  run apply_pain
  [[ "${output}" != *"-n C-h if-shell"* ]]
}

@test "applier - smart vim navigation can be enabled on tmux 2.4 and up" {
  tmux set-option -gq "@pane_control_vim_navigation" "on"
  run apply_pain
  [[ "${output}" == *"if-shell"* ]]
  [[ "${output}" == *"-n C-h if-shell"* ]]
  [[ "${output}" == *"copy-mode-vi C-h select-pane -L"* ]]
}

@test "applier - smart vim navigation binds the previous-pane chord" {
  tmux set-option -gq "@pane_control_vim_navigation" "on"
  run apply_pain
  [[ "${output}" == *"-n C-\\ if-shell"* ]]
  [[ "${output}" == *"select-pane -l"* ]]
  [[ "${output}" == *"copy-mode-vi C-\\ select-pane -l"* ]]
}

@test "applier - the vim detection pattern is configurable" {
  tmux set-option -gq "@pane_control_vim_navigation" "on"
  tmux set-option -gq "@pane_control_vim_pattern" "(my-editor)"
  run apply_pain
  [[ "${output}" == *"(my-editor)"* ]]
}

@test "applier - smart vim navigation is skipped below tmux 2.4" {
  tmux set-option -gq "@pane_control_vim_navigation" "on"
  _tmux_version_string() { echo "tmux 2.2"; }
  run apply_pain
  [[ "${output}" != *"-n C-h if-shell"* ]]
}

@test "applier - smart split chooses the longer axis and keeps the path" {
  run apply_pain
  [[ "${output}" == *'* if-shell [ #{pane_width} -gt #{pane_height} ] split-window -h -c #{pane_current_path} split-window -v -c #{pane_current_path}'* ]]
}

@test "applier - smart split key is configurable" {
  tmux set-option -gq "@pane_control_smart_split_key" "o"
  run apply_pain
  [[ "${output}" == *"o if-shell [ #{pane_width} -gt #{pane_height} ]"* ]]
}

@test "applier - join and break pane bindings" {
  run apply_pain
  [[ "${output}" == *"@ command-prompt -p join pane from: join-pane -h -s '%%'"* ]]
  [[ "${output}" == *"! break-pane"* ]]
}

@test "applier - move window to session prompts" {
  run apply_pain
  [[ "${output}" == *". command-prompt -p move window to session: move-window -t '%%'"* ]]
}

@test "applier - kill window confirms first" {
  run apply_pain
  [[ "${output}" == *"& confirm-before -p kill-window #W? (y/n) kill-window"* ]]
}

@test "applier - swap pane prev and next are repeatable" {
  run apply_pain
  [[ "${output}" == *"bind-key -r -N Swap pane up { swap-pane -U"* ]]
  [[ "${output}" == *"bind-key -r -N Swap pane down } swap-pane -D"* ]]
}

@test "applier - promote uses the top-left token on tmux 3.0 and up" {
  run apply_pain
  [[ "${output}" == *"+ swap-pane -d -t {top-left}"* ]]
}

@test "applier - promote falls back to pane index 0 below tmux 3.0" {
  _tmux_version_string() { echo "tmux 2.9"; }
  run apply_pain
  [[ "${output}" == *"+ swap-pane -d -t 0"* ]]
  [[ "${output}" != *"{top-left}"* ]]
}

@test "applier - marked-pane swap workflow needs tmux 2.1" {
  run apply_pain
  [[ "${output}" == *"m select-pane -m"* ]]
  [[ "${output}" == *"= swap-pane"* ]]
}

@test "applier - marked-pane swap workflow is skipped below tmux 2.1" {
  _tmux_version_string() { echo "tmux 2.0"; }
  run apply_pain
  [[ "${output}" != *"select-pane -m"* ]]
  [[ "${output}" != *"= swap-pane"* ]]
}

@test "applier - layout preset bindings" {
  run apply_pain
  [[ "${output}" == *"E select-layout even-horizontal"* ]]
  [[ "${output}" == *"V select-layout even-vertical"* ]]
  [[ "${output}" == *"B select-layout main-vertical"* ]]
}

@test "applier - respawn pane confirms and kills the old process" {
  run apply_pain
  [[ "${output}" == *"R confirm-before -p respawn-pane? (y/n) respawn-pane -k"* ]]
}

@test "applier - capture scrollback to a file prompts for the path" {
  run apply_pain
  [[ "${output}" == *"C command-prompt -p save scrollback to: -I ${HOME}/tmux-scrollback.log capture-pane -S - ; save-buffer '%%' ; delete-buffer"* ]]
}

@test "applier - name pane binding needs tmux 2.6" {
  run apply_pain
  [[ "${output}" == *"P command-prompt -p pane title: select-pane -T '%%'"* ]]
}

@test "applier - name pane binding is skipped below tmux 2.6" {
  _tmux_version_string() { echo "tmux 2.5"; }
  run apply_pain
  [[ "${output}" != *"select-pane -T"* ]]
}

@test "applier - pane titles in the border are opt-in and need tmux 2.3" {
  run apply_pain
  [[ "${output}" != *"pane-border-status"* ]]
  tmux set-option -gq "@pane_control_pane_titles" "on"
  run apply_pain
  [[ "${output}" == *"set-option -g pane-border-status top"* ]]
  [[ "${output}" == *"set-option -g pane-border-format  #{pane_index}: #{pane_title} "* ]]
}

@test "applier - pane titles in the border are skipped below tmux 2.3" {
  tmux set-option -gq "@pane_control_pane_titles" "on"
  _tmux_version_string() { echo "tmux 2.2"; }
  run apply_pain
  [[ "${output}" != *"pane-border-status"* ]]
}

@test "applier - scratch popup needs tmux 3.2 and opens a default shell" {
  run apply_pain
  [[ "${output}" == *"g display-popup -E -d #{pane_current_path} -w 80% -h 80%"* ]]
}

@test "applier - scratch popup runs a configured command" {
  tmux set-option -gq "@pane_control_scratch_command" "lazygit"
  run apply_pain
  [[ "${output}" == *"display-popup -E -d #{pane_current_path} -w 80% -h 80% lazygit"* ]]
}

@test "applier - scratch popup is skipped below tmux 3.2" {
  _tmux_version_string() { echo "tmux 3.1"; }
  run apply_pain
  [[ "${output}" != *"display-popup"* ]]
}

@test "applier - no-wrap pane selection is off by default" {
  run apply_pain
  [[ "${output}" != *"pane_at_left"* ]]
  [[ "${output}" == *"h select-pane -L"* ]]
}

@test "applier - no-wrap pane selection guards every edge on tmux 2.6 and up" {
  tmux set-option -gq "@pane_control_no_wrap" "on"
  run apply_pain
  [[ "${output}" == *"h if-shell -F #{pane_at_left} select-pane select-pane -L"* ]]
  [[ "${output}" == *"j if-shell -F #{pane_at_bottom} select-pane select-pane -D"* ]]
  [[ "${output}" == *"k if-shell -F #{pane_at_top} select-pane select-pane -U"* ]]
  [[ "${output}" == *"l if-shell -F #{pane_at_right} select-pane select-pane -R"* ]]
}

@test "applier - no-wrap pane selection is skipped below tmux 2.6" {
  tmux set-option -gq "@pane_control_no_wrap" "on"
  _tmux_version_string() { echo "tmux 2.5"; }
  run apply_pain
  [[ "${output}" != *"pane_at_left"* ]]
  [[ "${output}" == *"h select-pane -L"* ]]
}

@test "applier - vim navigation restores a prefixed clear-screen on C-l" {
  tmux set-option -gq "@pane_control_vim_navigation" "on"
  run apply_pain
  [[ "${output}" == *"C-l send-keys C-l"* ]]
}

@test "applier - disabled keys skip the new bindings too" {
  tmux set-option -gq "@pane_control_disabled_keys" "@ ! + g"
  run apply_pain
  [[ "${output}" != *"break-pane"* ]]
  [[ "${output}" != *"join-pane"* ]]
  [[ "${output}" != *"swap-pane -d -t"* ]]
  [[ "${output}" != *"display-popup"* ]]
}

@test "applier - new feature keys are all configurable" {
  tmux set-option -gq "@pane_control_join_key" "J"
  tmux set-option -gq "@pane_control_scratch_key" "G"
  tmux set-option -gq "@pane_control_respawn_key" "X"
  run apply_pain
  [[ "${output}" == *"J command-prompt -p join pane from:"* ]]
  [[ "${output}" == *"G display-popup -E"* ]]
  [[ "${output}" == *"X confirm-before -p respawn-pane?"* ]]
}
