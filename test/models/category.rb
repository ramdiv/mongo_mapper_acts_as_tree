require "mongo_mapper"
require "mongo_mapper_acts_as_tree"

class Category
  include MongoMapper::Document
  include MongoMapper::Acts::Tree
  
  key :name, String
  
  acts_as_tree
end