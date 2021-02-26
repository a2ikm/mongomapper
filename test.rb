require "bundler/inline"

gemfile(false) do
  source "https://rubygems.org"
  gem "activesupport", "~> #{ENV.fetch("RAILS_VERSION")}"
  gem "activemodel", "~> #{ENV.fetch("RAILS_VERSION")}"
end

require "minitest/autorun"
require "active_support"
require "active_support/core_ext"
require "active_model"

class Key
  attr_accessor :name, :type, :ivar

  def initialize(*args)
    @name, @type = args.shift.to_s, args.shift

    @ivar = :"@#{name}"
  end

  def get(value)
    value = type ? type.from_mongo(value) : value

    value
  end

  def set(value)
    # Avoid tap here so we don't have to create a block binding.
    type ? type.to_mongo(value) : value.to_mongo
  end
end

class String
  def self.to_mongo(value)
    value && value.to_s
  end

  def self.from_mongo(value)
    value && value.to_s
  end
end

class Answer
  def self.keys
    @keys ||= {}
  end

  def self.key(*args)
    Key.new(*args).tap do |key|
      keys[key.name] = key
    end
  end

  key :body, String



  def initialize(attrs={})
    attrs.each_pair do |name, value|
      key         = self.class.keys[name.to_s]
      as_mongo    = key.set(value)
      as_typecast = key.get(as_mongo)
      instance_variable_set key.ivar, as_typecast
    end
  end
end

class BugTest < Minitest::Test
  def test_to_json
    answer = Answer.new(body: "42")
    json = [answer].to_json
    assert_equal "42", JSON.parse(json)[0]["body"]
  end
end
