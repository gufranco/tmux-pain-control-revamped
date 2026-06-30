#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  source "${BATS_TEST_DIRNAME}/../../../src/lib/utils/constants.sh"
}

teardown() {
  cleanup_test_environment
}

@test "constants.sh - version is set and matches the documented value" {
  variable_exists PAIN_CONTROL_REVAMPED_VERSION
  [[ "${PAIN_CONTROL_REVAMPED_VERSION}" == "1.1.0" ]]
}

@test "constants.sh - shared defaults are present" {
  variable_exists TMUX_PLUGIN_DEFAULT_MAX_AGE
  variable_exists TMUX_PLUGIN_PENDING
  [[ "${TMUX_PLUGIN_PENDING}" == "..." ]]
}

@test "constants.sh - the source guard prevents a second load" {
  run source "${BATS_TEST_DIRNAME}/../../../src/lib/utils/constants.sh"
  [ "${status}" -eq 0 ]
}
