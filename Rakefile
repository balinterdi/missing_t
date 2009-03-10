require 'rubygems'
require 'rake'
require 'echoe'

Echoe.new('missing_t', '0.1.2') do |p|
  p.description    = "See all the missing I18n translations in your Rails project"
  p.url            = "http://github.com/balinterdi/missing_t"
  p.author         = "Balint Erdi"
  p.email          = "balint.erdi@gmail.com"
  p.ignore_pattern = ["tmp/*", "script/*"]
  p.development_dependencies = []
end

Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].sort.each { |ext| load ext }
