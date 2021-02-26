require 'bundler/setup'
Bundler.require(:default)

class Answer
  include MongoMapper::Document

  key :body, String
end
