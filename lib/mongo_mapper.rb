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
  autoload :Plugins,                'mongo_mapper/plugins'
  autoload :Translation,            'mongo_mapper/translation'
  autoload :Version,                'mongo_mapper/version'
  autoload :Utils,                  'mongo_mapper/utils'

  module Plugins
    autoload :Associations,       'mongo_mapper/plugins/associations'
    autoload :Keys,               'mongo_mapper/plugins/keys'

    module Associations
      autoload :Base,                         'mongo_mapper/plugins/associations/base'
      autoload :ManyAssociation,              'mongo_mapper/plugins/associations/many_association'
      autoload :SingleAssociation,            'mongo_mapper/plugins/associations/single_association'
      autoload :BelongsToAssociation,         'mongo_mapper/plugins/associations/belongs_to_association'
      autoload :OneAssociation,               'mongo_mapper/plugins/associations/one_association'

      autoload :Proxy,                        'mongo_mapper/plugins/associations/proxy/proxy'
      autoload :Collection,                   'mongo_mapper/plugins/associations/proxy/collection'
      autoload :EmbeddedCollection,           'mongo_mapper/plugins/associations/proxy/embedded_collection'
      autoload :ManyDocumentsProxy,           'mongo_mapper/plugins/associations/proxy/many_documents_proxy'
      autoload :BelongsToProxy,               'mongo_mapper/plugins/associations/proxy/belongs_to_proxy'
      autoload :BelongsToPolymorphicProxy,    'mongo_mapper/plugins/associations/proxy/belongs_to_polymorphic_proxy'
      autoload :ManyPolymorphicProxy,         'mongo_mapper/plugins/associations/proxy/many_polymorphic_proxy'
      autoload :ManyEmbeddedProxy,            'mongo_mapper/plugins/associations/proxy/many_embedded_proxy'
      autoload :ManyEmbeddedPolymorphicProxy, 'mongo_mapper/plugins/associations/proxy/many_embedded_polymorphic_proxy'
      autoload :ManyDocumentsAsProxy,         'mongo_mapper/plugins/associations/proxy/many_documents_as_proxy'
      autoload :OneProxy,                     'mongo_mapper/plugins/associations/proxy/one_proxy'
      autoload :OneAsProxy,                   'mongo_mapper/plugins/associations/proxy/one_as_proxy'
      autoload :OneEmbeddedProxy,             'mongo_mapper/plugins/associations/proxy/one_embedded_proxy'
      autoload :OneEmbeddedPolymorphicProxy,  'mongo_mapper/plugins/associations/proxy/one_embedded_polymorphic_proxy'
      autoload :InArrayProxy,                 'mongo_mapper/plugins/associations/proxy/in_array_proxy'
      autoload :InForeignArrayProxy,          'mongo_mapper/plugins/associations/proxy/in_foreign_array_proxy'
    end
  end
end

Dir[File.join(File.dirname(__FILE__), 'mongo_mapper', 'extensions', '*.rb')].each do |extension|
  require extension
end

ActiveSupport.run_load_hooks(:mongo_mapper, MongoMapper)
