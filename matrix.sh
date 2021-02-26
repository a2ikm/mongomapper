#!/bin/sh

for rbenv_version in "2.7.2" "3.0.0"; do
  for gemfile in "gemfiles/rails6_0.gemfile" "gemfiles/rails6_1.gemfile"; do
    echo "RBENV_VERSION=$rbenv_version BUNDLE_GEMFILE=$gemfile bundle exec rspec"
    (RBENV_VERSION=$rbenv_version BUNDLE_GEMFILE=$gemfile bundle exec rspec --out /dev/null && echo "success") || echo "fail"
  done
done
