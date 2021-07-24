#!/bin/bash
# shellcheck disable=SC1090,SC1091

# Note: we do _not_ call __lp_set_prompt directly in this file, as we do
# elsewhere; the idea is to check that it is properly integrated with
# bash-preexec.sh.

function setup_bash_preexec() {
  source "/home/ismith/.bash-preexec.sh"
  # Not sure why this is necessary here, when my .bashrc doesn't need it, b

  # ... PROMPT_COMMAND has the __bp_install_string if I don't.
  __bp_install
}

function setup_liquidprompt() {
  HOME=/home/user
  PWD=$HOME
  PS1="$ "
  . ../liquidprompt --no-activate

  # lp_theme activates liquid prompt a second time, which serves to double-check
  # that we only add __lp_set_prompt to bash-preexec's precmd_functions _once_
  lp_activate --no-config
  lp_theme default
}

function setup() {
    setup_bash_preexec
    setup_liquidprompt
}

function test_bash_preexec_with_LP_RUNTIME {
  (
    setup

    sleep 3 # should get "3s" in prompt
    $PROMPT_COMMAND
    assertContains "$PS1" "${LP_COLOR_RUNTIME}3s${NO_COL}"
  )
}

function test_bash_preexec_with_LP_ERR {
  (
    setup

    export LP_ENABLE_ERROR=1
    false # should get "1" in prompt
    $PROMPT_COMMAND
    assertContains "$PS1" "${LP_COLOR_ERR}1${NO_COL}"
  )
}


. ./shunit2
