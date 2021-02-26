# encoding: UTF-8
module MongoMapper
  module Document
    extend ActiveSupport::Concern
    extend Plugins

    include Plugins::ActiveModel
    include Plugins::Document
    include Plugins::Dumpable
    include Plugins::Querying # for now needs to be before associations (save_to_collection)
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
    include Plugins::Persistence
    include Plugins::Accessible
    include Plugins::Protected
    include Plugins::Rails
    include Plugins::Safe # needs to be after querying (save_to_collection)
    include Plugins::Sci

    included do
      extend Plugins
      extend Translation
    end
  end # Document
end # MongoMapper
