# encoding: UTF-8
require 'active_support'
require 'active_support/core_ext'
require 'active_model'

module MongoMapper
  module Plugins
    autoload :Keys,               'mongo_mapper/plugins/keys'
  end
end
