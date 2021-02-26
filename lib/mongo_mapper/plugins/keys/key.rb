# encoding: UTF-8
module MongoMapper
  module Plugins
    module Keys
      class Key
        RESERVED_KEYS = %w( class object_id attributes )

        attr_accessor :name, :type, :options, :default, :ivar, :accessors

        def initialize(*args)
          options_from_args = args.extract_options!
          @name, @type = args.shift.to_s, args.shift
          self.options = (options_from_args || {}).symbolize_keys
          @typecast    = @options[:typecast]
          @accessors   = Array(@options[:accessors]).compact.map &:to_s
          @has_default  = !!options.key?(:default)
          self.default = self.options[:default] if default?

          @ivar = :"@#{name}" if valid_ruby_name?
        end

        def persisted_name
          @name
        end

        def ==(other)
          @name == other.name && @type == other.type
        end

        def number?
          type == Integer || type == Float
        end

        def default?
          @has_default
        end

        def get(value)
          value = type ? type.from_mongo(value) : value

          if @typecast
            klass = typecast_class # Don't make this lookup on every call
            # typecast assumes array-ish object.
            value = value.map { |v| klass.from_mongo(v) }
            # recast it in the original type
            value = type.from_mongo(value)
          end

          value
        end

        def set(value)
          # Avoid tap here so we don't have to create a block binding.
          value = type ? type.to_mongo(value) : value.to_mongo

          if @typecast
            klass = typecast_class  # Don't make this lookup on every call
            value.map { |v| klass.to_mongo(v) }
          else
            value
          end
        end

        def default_value
          return unless default?

          if default.instance_of? Proc
            default.call
          else
            # Using Marshal is easiest way to get a copy of mutable objects
            # without getting an error on immutable objects
            Marshal.load(Marshal.dump(default))
          end
        end

        def valid_ruby_name?
          !!@name.match(/\A[a-z_][a-z0-9_]*\z/i)
        end

        def reserved_name?
          RESERVED_KEYS.include?(@name)
        end

        def read_accessor?
          any_accessor? ["read"]
        end

        def write_accessor?
          any_accessor? ["write"]
        end

        def predicate_accessor?
          any_accessor? ["present", "predicate", "boolean"]
        end

        def any_accessor?(arr_opt = [])
          return true if @accessors.empty?
          return false unless (@accessors & ["skip", "none"]).empty?
          return !(@accessors & arr_opt).empty?
        end

      private

        def typecast_class
          @typecast_class ||= options[:typecast].constantize
        end
      end
    end
  end
end
