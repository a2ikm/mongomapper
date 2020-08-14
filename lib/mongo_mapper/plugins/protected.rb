# encoding: UTF-8
require 'set'

module MongoMapper
  module Plugins
    module Protected
      extend ActiveSupport::Concern

      included do
        class_attribute :protected_attributes
      end

      module ClassMethods
        def attr_protected(*attrs)
          raise AccessibleOrProtected.new(name) if try(:accessible_attributes?)
          self.protected_attributes = Set.new(attrs) + (protected_attributes || [])
        end

        def key(*args)
          key = super
          attr_protected key.name.to_sym if key.options[:protected]
          key
        end
      end

      def attributes=(attrs={})
        super(filter_protected_attrs(attrs))
      end

      def update_attributes(attrs={})
        super(filter_protected_attrs(attrs))
      end

      def update_attributes!(attrs={})
        super(filter_protected_attrs(attrs))
      end

    protected

      def filter_protected_attrs(attrs)
        return attrs if protected_attributes.blank? || attrs.blank?
        attrs.dup.delete_if { |key, val| protected_attributes.include?(key.to_sym) }.tap do |new_attrs|
          if attrs.count > new_attrs.count
            keys = attrs.keys.map(&:to_sym) - new_attrs.keys.map(&:to_sym)
            MongoMapper.logger.warn "WARNING: Can’t mass-assign protected attributes: #{keys.join(", ")}"
          end
        end
      end
    end
  end
end
