# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{missing_t}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Balint Erdi"]
  s.date = %q{2009-03-03}
  s.default_executable = %q{missing_t}
  s.description = %q{See all the missing I18n translations in your Rails project}
  s.email = %q{balint.erdi@gmail.com}
  s.executables = ["missing_t"]
  s.extra_rdoc_files = ["bin/missing_t", "lib/missing_t.rb", "README.rdoc", "tasks/missing_t.rake"]
  s.files = ["bin/missing_t", "lib/missing_t.rb", "Manifest", "Rakefile", "README.rdoc", "spec/missing_t_spec.rb", "spec/spec_helper.rb", "tasks/missing_t.rake", "missing_t.gemspec"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/balinterdi/missing_t}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Missing_t", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{missing_t}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{See all the missing I18n translations in your Rails project}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
