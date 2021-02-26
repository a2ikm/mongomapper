#!/bin/sh

for rbenv_version in "2.7.2" "3.0.0"; do
  for rails_version in "6.0.0" "6.1.0"; do
    echo "RBENV_VERSION=$rbenv_version RAILS_VERSION=$rails_version ruby test.rb"
    RBENV_VERSION=$rbenv_version RAILS_VERSION=$rails_version ruby test.rb
  done
done
