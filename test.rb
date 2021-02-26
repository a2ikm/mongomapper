require "bundler/inline"

gemfile(false) do
  source "https://rubygems.org"
  gem "activesupport", "~> #{ENV.fetch("RAILS_VERSION")}"
end

require "minitest/autorun"
require "active_support/json/encoding"

class Answer
  def initialize
    @body = "42"
  end
end

class BugTest < Minitest::Test
  def test_to_json_object
    answer = Answer.new
    assert_equal '{"body":"42"}', answer.to_json
  end

  def test_to_json_object_in_array
    answer = Answer.new
    assert_equal '[{"body":"42"}]', [answer].to_json
  end
end
