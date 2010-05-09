require "rake"

begin
  require "jeweler"
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "rrrdtool"
    gemspec.summary = "Round robin database pattern via Redis sorted sets"
    gemspec.description = gemspec.summary
    gemspec.email = "ilya@igvita.com"
    gemspec.homepage = "http://github.com/igrigorik/rrrdtool"
    gemspec.authors = ["Ilya Grigorik"]
    gemspec.required_ruby_version = ">= 1.8"
    gemspec.add_dependency("redis", ">= 1.9")
    gemspec.rubyforge_project = "rrrdtool"
  end

  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available: gem install jeweler"
end