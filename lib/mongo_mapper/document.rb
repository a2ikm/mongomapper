# encoding: UTF-8
module MongoMapper
  module Document
    extend ActiveSupport::Concern

    # include Plugins::Associations
    include Plugins::Keys
  end # Document
end # MongoMapper
