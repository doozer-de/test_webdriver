#!/bin/bash
# Fast fail the script on failures.
set -e

if [ -z "$TASK" ]; then
  echo -e "TASK environment variable must be set!"
  exit 1
fi

if [ ! -z "$PKG" ]; then
    pushd $PKG
fi

pub upgrade

case $TASK in
dartanalyzer) echo
  echo -e "TASK: dartanalyzer"
  dartanalyzer --fatal-infos --fatal-warnings .
  ;;
dartfmt) echo
  echo -e "TASK: dartfmt"
  dartfmt -n --set-exit-if-changed .
  ;;
test) echo
  echo -e "TASK: test"
  pub run test
  ;;
test_1) echo
  echo -e "TASK: test_1"
  pub run test --run-skipped
  ;;
*) echo -e "Not expecting TASK '${TASK}'. Error!"
  exit 1
  ;;
esac