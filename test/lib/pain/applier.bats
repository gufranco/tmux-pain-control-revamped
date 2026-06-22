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

@test "applier - synchronize toggle is bound and configurable" {
  run apply_pain
  [[ "${output}" == *"S set-window-option synchronize-panes"* ]]
  tmux set-option -gq "@pane_control_sync_key" "Y"
  run apply_pain
  [[ "${output}" == *"Y set-window-option synchronize-panes"* ]]
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
  [[ "${output}" != *"if-shell"* ]]
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
  [[ "${output}" != *"if-shell"* ]]
}
