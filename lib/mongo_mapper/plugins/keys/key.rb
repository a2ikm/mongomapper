# encoding: UTF-8
module MongoMapper
  module Plugins
    module Keys
      class Key
        RESERVED_KEYS = %w( class object_id attributes )

        attr_accessor :name, :type, :ivar

        def initialize(*args)
          args.extract_options!
          @name, @type = args.shift.to_s, args.shift

          @ivar = :"@#{name}"
        end

        def persisted_name
          @name
        end

        def ==(other)
          @name == other.name && @type == other.type
        end

        def get(value)
          value = type ? type.from_mongo(value) : value

          value
        end

        def set(value)
          # Avoid tap here so we don't have to create a block binding.
          type ? type.to_mongo(value) : value.to_mongo
        end
      end
    end
  end
end
