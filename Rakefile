require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "ramdiv-mongo_mapper_acts_as_tree"
    gem.summary = %Q{ActsAsTree plugin for MongoMapper}
    gem.description = %Q{Port of the old, venerable ActsAsTree with a bit of a twist}
    gem.email = "jakob.vidmar@gmail.com"
    gem.homepage = "http://github.com/ramdiv/mongo_mapper_acts_as_tree"
    gem.authors = ["Jakob Vidmar"]
    gem.add_dependency("mongo_mapper", ">= 0.6.8")
    
    gem.add_development_dependency "shoulda", ">=2.10.2"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "mongo_mapper_acts_as_tree #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
