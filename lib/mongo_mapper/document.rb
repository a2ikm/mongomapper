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
    include Plugins::Inspect
    include Plugins::Indexes
    include Plugins::Keys
    include Plugins::Keys::Static
    include Plugins::Dirty # for now dirty needs to be after keys
    include Plugins::Logger
    include Plugins::Modifiers
    include Plugins::Pagination

    included do
      extend Plugins
      extend Translation
    end
  end # Document
end # MongoMapper
