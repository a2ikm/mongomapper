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

        def to_mongo(instance)
          instance && instance.to_mongo
        end

        def from_mongo(value)
          value && (value.instance_of?(self) ? value : load(value))
        end
      end

      def initialize(attrs={})
        @_new = true
        self.attributes = attrs
        yield self if block_given?
      end

      def persisted?
        !new? && !destroyed?
      end

      def attributes=(attrs)
        return if attrs == nil || attrs.blank?

        attrs.each_pair do |key, value|
          self[key] = value
        end
      end

      # NOTE: We can't use alias_method here as we need the #attributes=
      # superclass method to get called (for example:
      # MongoMapper::Plugins::Accessible filters non-permitted parameters
      # through `attributes=`
      def assign_attributes(new_attributes)
        self.attributes = new_attributes
      end

      def to_mongo(include_abbreviatons = true)
        Hash.new.tap do |attrs|
          self.class.unaliased_keys.each do |name, key|
            value = self.read_key(key.name)
            if !value.nil?
              attrs[include_abbreviatons && key.persisted_name || name] = key.set(value)
            end
          end
        end
      end

      def attributes
        to_mongo(false).with_indifferent_access
      end

      def assign(attrs={})
        warn "[DEPRECATION] #assign is deprecated, use #attributes="
        self.attributes = attrs
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
            if key.ivar
              instance_variable_set key.ivar, key.get(nil)
            end
          end
        end
      end

      def [](key_name); read_key(key_name); end
      def attribute(key_name); read_key(key_name); end

      def []=(name, value)
        write_key(name, value)
      end

      def key_names
        @key_names ||= keys.keys
      end

    private

      # This exists to be patched over by plugins, while letting us still get to the undecorated
      # version of the method.
      def write_key(name, value)
        internal_write_key(name.to_s, value)
      end

      def internal_write_key(name, value, cast = true)
        key         = self.class.keys[name]
        as_mongo    = cast ? key.set(value) : value
        as_typecast = key.get(as_mongo)
        if key.ivar
          instance_variable_set key.ivar, as_typecast
        end
        value
      end
    end
  end
end
