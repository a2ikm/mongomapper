require "bundler/inline"

gemfile(true) do
  source "https://rubygems.org"
  gemspec :path => './'
  gem "rails", "~> #{ENV.fetch("RAILS_VERSION")}"
end

require "minitest/autorun"

class Answer
  include MongoMapper::Document

  key :body, String
end

class BugTest < Minitest::Test
  def test_to_json
    answer = Answer.new(body: "42")
    json = [answer].to_json
    assert_equal "42", JSON.parse(json)[0]["body"]
  end
end
