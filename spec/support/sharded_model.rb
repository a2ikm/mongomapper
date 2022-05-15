class ShardedModel
  include MongoMapper::Document

  key :first_name, String
  key :last_name, String
  # shard_key :first_name, :last_name
end

if ENV["ENABLE_SHARDING"]
  client = MongoMapper.connection
  database = MongoMapper.database

  # https://www.mongodb.com/docs/manual/reference/command/enableSharding/#mongodb-dbcommand-dbcmd.enableSharding
  client.use(:admin).command(enableSharding: database.name)

  # https://www.mongodb.com/docs/manual/reference/command/shardCollection/#mongodb-dbcommand-dbcmd.shardCollection
  # Note 1: this command automatically creates the index for the empty collection
  # Note 2: shard key can contain at most one 'hashed' field, and/or multiple numerical fields set to a value of 1
  client.use(:admin).command(
    shardCollection: [database.name, ShardedModel.collection.name].join("."),
    key: {
      first_name: "hashed",
      last_name: 1,
    },
  )
end

