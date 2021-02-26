require "bundler/inline"

gemfile(false) do
  source "https://rubygems.org"
  gem "activesupport", "~> #{ENV.fetch("RAILS_VERSION")}"
end

require "minitest/autorun"
require "active_support"
require "active_support/core_ext"

class Answer
  def initialize
    instance_variable_set(:"@body", "42")
  end
end

class BugTest < Minitest::Test
  def test_to_json
    answer = Answer.new
    json = [answer].to_json
    assert_equal "42", JSON.parse(json)[0]["body"]
  end
end
