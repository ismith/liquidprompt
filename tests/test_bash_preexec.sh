#!/bin/bash
# shellcheck disable=SC1090,SC1091,SC2031,SC2030

# Note: we do not call __lp_set_prompt directly in this file, as we do
# elsewhere; the idea is to check that it is properly integrated with
# bash-preexec.sh.

if [[ "$SHELL" != *bash ]]; then
  echo "$0 is irrelevant for non-bash shells, and this is ${SHELL}"
  exit 0
fi

function setup_bash_preexec() {
  source "/home/ismith/.bash-preexec.sh"
  # Not sure why this is necessary here, when my .bashrc doesn't need it, but
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

### Begin actual test functions. (Above this line are setup helpers.)

function test_bash_preexec_with_LP_RUNTIME {
  (
    setup

    sleep 3 # should get "3s" in prompt
    $PROMPT_COMMAND
    assertContains "$PS1" "${LP_COLOR_RUNTIME}3s${NO_COL}"
  )
}

# Check it works with bash_preexec off
function test_no_bash_preexec_with_LP_RUNTIME {
  (
    setup_liquidprompt

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

# Check it works with bash_preexec off
function test_no_bash_preexec_with_LP_ERR {
  (
    setup_liquidprompt

    export LP_ENABLE_ERROR=1
    false # should get "1" in prompt
    $PROMPT_COMMAND
    assertContains "$PS1" "${LP_COLOR_ERR}1${NO_COL}"
  )
}

function test_bash_preexec_with_prompt_off {
  (
    setup_bash_preexec

    local -a precmd_functions_before_liquid_prompt
    local -a precmd_functions_before_liquid_prompt
    precmd_functions_before_liquidprompt=(${precmd_functions[@]+"${precmd_functions[@]}"} )
    preexec_functions_before_liquidprompt=(${preexec_functions[@]+"${preexec_functions[@]}"} )

    # This function checks that liquidprompt returns precmd_functions and
    # preexec_functions to their original state after prompt_off is run - it'd
    # be "too easy" if their original state was empty, let's make sure they're
    # not.
    assertNotEquals "0" "${#precmd_functions_before_liquidprompt[@]}"
    assertNotEquals "0" "${#preexec_functions_before_liquidprompt[@]}"
    assertNotEquals "0" "${#precmd_functions[@]}"
    assertNotEquals "0" "${#preexec_functions[@]}"

    # Check we copied them correctly
    assertEquals "${precmd_functions[@]}" "${precmd_functions_before_liquidprompt[@]}"
    assertEquals "${preexec_functions[@]}" "${preexec_functions_before_liquidprompt[@]}"

    setup_liquidprompt
    # We expect liquidprompt to add new entries to precmd_functions and
    # preexec_functions, so the arrays should no longer be equal.
    assertNotEquals "${precmd_functions[@]}" "${precmd_functions_before_liquidprompt[@]}"
    assertNotEquals "${preexec_functions[@]}" "${preexec_functions_before_liquidprompt[@]}"
    precmd_functions_after_liquidprompt=(${precmd_functions[@]+"${precmd_functions[@]}"} )
    preexec_functions_after_liquidprompt=(${preexec_functions[@]+"${preexec_functions[@]}"} )

    # This just checks that we did in fact get liquidprompt turned on.
    export LP_ENABLE_ERROR=1
    false # should get "1" in prompt
    $PROMPT_COMMAND
    assertContains "$PS1" "${LP_COLOR_ERR}1${NO_COL}"

    # Here's the function we're actually here to test.
    prompt_off

    # With prompt off, not only should we not have a "1" in prompt, it should
    # just be back to plain old "$ "
    false
    $PROMPT_COMMAND
    assertNotContains "$PS1" "${LP_COLOR_ERR}1${NO_COL}"
    assertEquals "$PS1" "$ "

    # And, having run prompt_off, precmd_functions and preexec_functions should
    # be back to their original values.
    assertEquals \
      "${precmd_functions_before_liquidprompt[@]}" \
      "${precmd_functions[@]}"
    assertEquals \
      "${preexec_functions_before_liquidprompt[@]}" \
      "${preexec_functions[@]}"
  )
}


. ./shunit2
