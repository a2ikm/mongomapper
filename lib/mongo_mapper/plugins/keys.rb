# encoding: UTF-8
require 'mongo_mapper/plugins/keys/key'

module MongoMapper
  module Plugins
    module Keys
      extend ActiveSupport::Concern
      module ClassMethods
        def keys
          @keys ||= {}
        end

        def key(*args)
          Key.new(*args).tap do |key|
            keys[key.name] = key
          end
        end

        def key?(key)
          keys.key? key.to_s
        end
      end

      def initialize(attrs={})
        attrs.each_pair do |name, value|
          key         = self.class.keys[name.to_s]
          as_mongo    = key.set(value)
          as_typecast = key.get(as_mongo)
          instance_variable_set key.ivar, as_typecast
          value
        end
      end
    end
  end
end
