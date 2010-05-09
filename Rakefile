require "rake"

begin
  require "jeweler"
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "rrstat"
    gemspec.summary = "Round robin database via Redis sorted sets"
    gemspec.description = gemspec.summary
    gemspec.email = "ilya@igvita.com"
    gemspec.homepage = "http://github.com/igrigorik/rrstat"
    gemspec.authors = ["Ilya Grigorik"]
    gemspec.required_ruby_version = ">= 1.8"
    gemspec.add_dependency("redis", ">= 2.0.0")
    gemspec.rubyforge_project = "rrstat"
  end

  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available: gem install jeweler"
end