require 'rubygems'
gem "minitest"
require 'database_cleaner'
require "minitest/autorun"

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'mongo_mapper_tree'

MongoMapper.database = "mongo_mapper_tree-test"

Dir["#{File.dirname(__FILE__)}/models/*.rb"].each {|file| require file}

DatabaseCleaner.strategy = :truncation

def eql_arrays?(first, second)
  first.collect(&:_id).to_set == second.collect(&:_id).to_set
end
