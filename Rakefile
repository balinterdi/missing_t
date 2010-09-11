require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "missing_t"
    gemspec.summary = "See all the missing I18n translations in your Rails project"
    gemspec.description = <<-EOF
      With missing_t you can easily find all the missing i18n translations in your Rails project.
    EOF
    gemspec.email = "balint.erdi@gmail.com"
    gemspec.homepage = "http://github.com/balinterdi/missing_t"
    gemspec.authors = ["Balint Erdi"]
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

task :default => :spec

Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].sort.each { |ext| load ext }
