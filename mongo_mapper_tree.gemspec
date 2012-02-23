# encoding: UTF-8
require File.expand_path('../lib/version', __FILE__)
Gem::Specification.new do |s|
  s.name           = 'mongo_mapper_tree'
  s.homepage       = 'http://github.com/Oktavilla/mongo_mapper_tree'
  s.summary        = 'An Acts As Tree like implementation for MongoMapper'
  s.description    = 'An Acts As Tree like implementation for MongoMapper based on mongo_mapper_acts_as_tree'
  s.require_path   = 'lib'
  s.authors        = ['Joel Junström']
  s.email          = ['joel.junstrom@oktavilla.se']
  s.version        = MongoMapperTree::Version
  s.platform       = Gem::Platform::RUBY
  s.files = Dir.glob("{lib,test}/**/*") + %w[LICENSE README.rdoc]

  s.test_files = Dir.glob("{test}/**/*")

  s.add_dependency 'mongo_mapper', '~> 0.9'
  s.add_development_dependency 'shoulda', '~> 2.10'
end
