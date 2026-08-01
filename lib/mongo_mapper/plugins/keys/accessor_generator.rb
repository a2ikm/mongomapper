# encoding: UTF-8
module MongoMapper
  module Plugins
    module Keys
      # Generates the reader / writer / predicate methods for a Key on a model.
      #
      # This is a collaborator object, not a mixin: it needs only the model and
      # the key, owns the per-model `MongoMapperKeys` accessor module, and is
      # invoked by Keys::ClassMethods#create_accessors_for rather than being
      # mixed into the model. Keeping it out of the model keeps accessor code
      # generation understandable on its own, without the rest of Keys in view.
      class AccessorGenerator
        ACCESSORS_MODULE_NAME = 'MongoMapperKeys'

        def initialize(model)
          @model = model
        end

        def generate(key, &block)
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

          accessors_module.module_eval(&block) if block

          @model.send(:include, accessors_module)
        end

        private

        # A module per model, created lazily and reused, into which the accessor
        # methods are defined and then included. Each subclass gets its own
        # (const_defined? with inherit: false), matching the previous behavior.
        def accessors_module
          if @model.const_defined?(ACCESSORS_MODULE_NAME, false)
            @model.const_get(ACCESSORS_MODULE_NAME)
          else
            @model.const_set(ACCESSORS_MODULE_NAME, Module.new)
          end
        end
      end
    end
  end
end
