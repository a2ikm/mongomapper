require 'bundler/setup'
Bundler.require(:default)

MongoMapper.connection = Mongo::Client.new(['127.0.0.1:27017'], :database => 'test')

class Answer
  include MongoMapper::Document

  key :body, String
end
