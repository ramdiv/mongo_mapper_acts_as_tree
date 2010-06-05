require "mongo_mapper"
require "mongo_mapper_acts_as_tree"

class Shape
  include MongoMapper::Document
  include MongoMapper::Acts::Tree
  
  key :name, String
  
  acts_as_tree :search_class => Shape
end

class Circle < Shape; end
class Square < Shape; end
