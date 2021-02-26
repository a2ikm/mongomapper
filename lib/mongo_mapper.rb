# encoding: UTF-8
require 'plucky'
require 'active_support'
require 'active_support/core_ext'
require 'active_model'

I18n.load_path << File.expand_path('../mongo_mapper/locale/en.yml', __FILE__)

module MongoMapper
  autoload :Error,                  'mongo_mapper/exceptions'
  autoload :DocumentNotFound,       'mongo_mapper/exceptions'
  autoload :InvalidScheme,          'mongo_mapper/exceptions'
  autoload :DocumentNotValid,       'mongo_mapper/exceptions'
  autoload :AccessibleOrProtected,  'mongo_mapper/exceptions'
  autoload :InvalidKey,             'mongo_mapper/exceptions'
  autoload :NotSupported,           'mongo_mapper/exceptions'

  autoload :Document,               'mongo_mapper/document'
  autoload :Version,                'mongo_mapper/version'

  module Plugins
    autoload :Keys,               'mongo_mapper/plugins/keys'
  end
end

Dir[File.join(File.dirname(__FILE__), 'mongo_mapper', 'extensions', '*.rb')].each do |extension|
  require extension
end
