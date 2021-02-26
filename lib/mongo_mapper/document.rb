# encoding: UTF-8
module MongoMapper
  module Document
    extend ActiveSupport::Concern
    extend Plugins

    include Plugins::Associations
    include Plugins::Keys

    included do
      extend Plugins
    end
  end # Document
end # MongoMapper
