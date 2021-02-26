#!/bin/sh

for rbenv_version in "2.7.2" "3.0.0"; do
  for as_version in "6.0.3.5" "6.1.3"; do
    echo "RBENV_VERSION=$rbenv_version AS_VERSION=$as_version ruby test.rb"
    RBENV_VERSION=$rbenv_version AS_VERSION=$rails_version ruby test.rb
  done
done
