# encoding: UTF-8
module MongoMapper
  module Document
    extend ActiveSupport::Concern
    extend Plugins

    include Plugins::ActiveModel
    include Plugins::Associations
    include Plugins::Keys

    included do
      extend Plugins
      extend Translation
    end
  end # Document
end # MongoMapper
