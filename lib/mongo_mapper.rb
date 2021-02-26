# encoding: UTF-8
require 'plucky'
require 'active_support'
require 'active_support/core_ext'
require 'active_model'

module MongoMapper
  autoload :Error,                  'mongo_mapper/exceptions'
  autoload :DocumentNotFound,       'mongo_mapper/exceptions'
  autoload :InvalidScheme,          'mongo_mapper/exceptions'
  autoload :DocumentNotValid,       'mongo_mapper/exceptions'
  autoload :AccessibleOrProtected,  'mongo_mapper/exceptions'
  autoload :InvalidKey,             'mongo_mapper/exceptions'
  autoload :NotSupported,           'mongo_mapper/exceptions'

  module Plugins
    autoload :Keys,               'mongo_mapper/plugins/keys'
  end
end
