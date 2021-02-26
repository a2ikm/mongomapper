require 'bundler/setup'
Bundler.require(:default)

MongoMapper.connection = Mongo::Client.new(['127.0.0.1:27017'], :database => 'test')
Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f}
