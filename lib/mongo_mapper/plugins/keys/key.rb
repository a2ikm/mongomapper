# encoding: UTF-8
module MongoMapper
  module Plugins
    module Keys
      class Key
        RESERVED_KEYS = %w( class object_id attributes )

        attr_accessor :name, :type, :options, :ivar

        def initialize(*args)
          options_from_args = args.extract_options!
          @name, @type = args.shift.to_s, args.shift
          self.options = (options_from_args || {}).symbolize_keys

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

        def get(value)
          value = type ? type.from_mongo(value) : value

          value
        end

        def set(value)
          # Avoid tap here so we don't have to create a block binding.
          type ? type.to_mongo(value) : value.to_mongo
        end

        def valid_ruby_name?
          !!@name.match(/\A[a-z_][a-z0-9_]*\z/i)
        end

        def reserved_name?
          RESERVED_KEYS.include?(@name)
        end
      end
    end
  end
end
