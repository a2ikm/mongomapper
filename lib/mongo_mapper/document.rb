# encoding: UTF-8
module MongoMapper
  module Document
    extend ActiveSupport::Concern
    extend Plugins

    include Plugins::ActiveModel
    include Plugins::Document
    include Plugins::Dumpable
    include Plugins::Associations
    include Plugins::Caching
    include Plugins::Clone
    include Plugins::DynamicQuerying
    include Plugins::Equality
    include Plugins::Keys

    included do
      extend Plugins
      extend Translation
    end
  end # Document
end # MongoMapper
