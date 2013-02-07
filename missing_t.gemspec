# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'missing_t'

Gem::Specification.new do |gem|
  gem.name          = "missing_t"
  gem.version       = MissingT::VERSION
  gem.authors       = ["Balint Erdi"]
  gem.email         = ["balint.erdi@gmail.com"]
  gem.description   = "Finds all the missing i18n translations in your Rails project"
  gem.summary       = "Finds all the missing i18n translations in your Rails project"
  gem.homepage      = "http://github.com/balinterdi/missing_t"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency 'rake', ['~> 10.0.3']
  gem.add_development_dependency 'rspec', ['~> 2.12.0']
  gem.add_development_dependency 'guard', ['~> 1.5.4']
  gem.add_development_dependency 'guard-rspec', ['~> 2.3.1']
  gem.add_development_dependency 'rb-fsevent', ['~> 0.9.1']
end
