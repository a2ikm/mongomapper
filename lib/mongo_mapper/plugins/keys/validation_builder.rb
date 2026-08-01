# encoding: UTF-8
module MongoMapper
  module Plugins
    module Keys
      # Registers ActiveModel validations for a Key based on its options.
      #
      # Collaborator object (not a mixin): it takes only (model, key) and drives
      # the model's public validates_* DSL. The option -> validation mapping is a
      # dispatch table applied in a fixed order, which keeps each rule small and
      # the whole well below the ABC size the inline if-chain used to carry.
      class ValidationBuilder
        # Applied in this order so validations register deterministically,
        # independent of the order the options happened to be given in.
        RULES = [
          [:required, lambda do |model, key, attribute|
            if key.type == Boolean
              model.validates_inclusion_of attribute, :in => [true, false]
            else
              model.validates_presence_of(attribute)
            end
          end],
          [:unique, lambda do |model, _key, attribute|
            model.validates_uniqueness_of(attribute)
          end],
          [:numeric, lambda do |model, key, attribute|
            number_options = key.type == Integer ? {:only_integer => true} : {}
            model.validates_numericality_of(attribute, number_options)
          end],
          [:format, lambda do |model, key, attribute|
            model.validates_format_of(attribute, :with => key.options[:format])
          end],
          [:in, lambda do |model, key, attribute|
            model.validates_inclusion_of(attribute, :in => key.options[:in])
          end],
          [:not_in, lambda do |model, key, attribute|
            model.validates_exclusion_of(attribute, :in => key.options[:not_in])
          end],
          [:length, lambda do |model, key, attribute|
            length_options = case key.options[:length]
            when Integer
              {:minimum => 0, :maximum => key.options[:length]}
            when Range
              {:within => key.options[:length]}
            when Hash
              key.options[:length]
            end
            model.validates_length_of(attribute, length_options)
          end],
        ].freeze

        def initialize(model)
          @model = model
        end

        def build(key)
          attribute = key.name.to_sym
          RULES.each do |option, rule|
            rule.call(@model, key, attribute) if key.options[option]
          end
        end
      end
    end
  end
end
