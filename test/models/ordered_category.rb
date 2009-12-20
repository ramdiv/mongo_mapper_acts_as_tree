require "mongo_mapper"
require "mongo_mapper_acts_as_tree"

class OrderedCategory
  include MongoMapper::Document
  include MongoMapper::Acts::Tree
  
  key :name,  String
  key :value, Integer
  
  acts_as_tree :order => "value asc"
end