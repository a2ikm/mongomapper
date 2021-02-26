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
        attrs.each_pair do |key, value|
          write_key(key, value)
        end
      end

      def attributes
        to_mongo(false).with_indifferent_access
      end

      def keys
        self.class.keys
      end

      def read_key(key_name)
        key_name_sym = key_name.to_sym
        if key = keys[key_name.to_s]
          if key.ivar && instance_variable_defined?(key.ivar)
            value = instance_variable_get(key.ivar)
          else
            instance_variable_set key.ivar, key.get(nil)
          end
        end
      end

    private

      # This exists to be patched over by plugins, while letting us still get to the undecorated
      # version of the method.
      def write_key(name, value)
        key         = self.class.keys[name.to_s]
        as_mongo    = key.set(value)
        as_typecast = key.get(as_mongo)
        instance_variable_set key.ivar, as_typecast
        value
      end
    end
  end
end
