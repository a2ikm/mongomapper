require "bundler/inline"

gemfile(false) do
  source "https://rubygems.org"
  gemspec :path => './'
  gem "rails", "~> #{ENV.fetch("RAILS_VERSION")}"
end

require "minitest/autorun"

class String
  def self.to_mongo(value)
    value && value.to_s
  end

  def self.from_mongo(value)
    value && value.to_s
  end
end

class Answer
  include MongoMapper::Plugins::Keys

  key :body, String
end

class BugTest < Minitest::Test
  def test_to_json
    answer = Answer.new(body: "42")
    json = [answer].to_json
    assert_equal "42", JSON.parse(json)[0]["body"]
  end
end
