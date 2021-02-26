# encoding: UTF-8
require 'mongo_mapper/plugins/keys/key'

module MongoMapper
  module Plugins
    module Keys
      extend ActiveSupport::Concern

      IS_RUBY_1_9 = method(:const_defined?).arity == 1

      included do
        extend ActiveSupport::DescendantsTracker
      end

      module ClassMethods
        def inherited(descendant)
          descendant.instance_variable_set(:@keys, keys.dup)
          super
        end

        def keys
          @keys ||= {}
        end

        def key(*args)
          Key.new(*args).tap do |key|
            keys[key.name] = key
            create_accessors_for(key) if key.valid_ruby_name? && !key.reserved_name?
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

      private

        def key_accessors_module_defined?
          # :nocov:
          if IS_RUBY_1_9
            const_defined?('MongoMapperKeys')
          else
            const_defined?('MongoMapperKeys', false)
          end
          # :nocov:
        end

        def accessors_module
          if key_accessors_module_defined?
            const_get 'MongoMapperKeys'
          else
            const_set 'MongoMapperKeys', Module.new
          end
        end

        def create_accessors_for(key)
          if key.read_accessor?
            accessors_module.module_eval(<<-end_eval, __FILE__, __LINE__+1)
              def #{key.name}
                read_key(:#{key.name})
              end

              def #{key.name}_before_type_cast
                read_key_before_type_cast(:#{key.name})
              end
            end_eval
          end

          if key.write_accessor?
            accessors_module.module_eval(<<-end_eval, __FILE__, __LINE__+1)
              def #{key.name}=(value)
                write_key(:#{key.name}, value)
              end
            end_eval
          end

          if key.predicate_accessor?
            accessors_module.module_eval(<<-end_eval, __FILE__, __LINE__+1)
              def #{key.name}?
                read_key(:#{key.name}).present?
              end
            end_eval
          end

          if block_given?
            accessors_module.module_eval do
              yield
            end
          end

          include accessors_module
        end
      end

      def initialize(attrs={})
        @_new = true
        init_ivars
        self.attributes = attrs
        yield self if block_given?
      end

      def persisted?
        !new? && !destroyed?
      end

      def attributes=(attrs)
        return if attrs == nil || attrs.blank?

        attrs.each_pair do |key, value|
          if respond_to?(:"#{key}=")
            self.send(:"#{key}=", value)
          else
            self[key] = value
          end
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

      def update_attributes(attrs={})
        self.attributes = attrs
        save
      end

      def update_attributes!(attrs={})
        self.attributes = attrs
        save!
      end

      def update_attribute(name, value)
        self.send(:"#{name}=", value)
        save(:validate => false)
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

    protected

      def unalias_key(name)
        name = name.to_s
        if key = keys[name]
          key.name
        else
          name
        end
      end

    private

      def init_ivars
        @__mm_keys = self.class.keys                                # Not dumpable
      end

      # This exists to be patched over by plugins, while letting us still get to the undecorated
      # version of the method.
      def write_key(name, value)
        init_ivars unless @__mm_keys
        internal_write_key(name.to_s, value)
      end

      def internal_write_key(name, value, cast = true)
        key         = @__mm_keys[name]
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
