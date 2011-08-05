class Category
  include MongoMapper::Document
  plugin MongoMapper::Plugins::Tree

  key :name, String
end