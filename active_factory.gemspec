# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{active_factory}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Alexey Tarasevich"]
  s.date = %q{2011-04-21}
  s.description = %q{Fixtures replacement with sweet syntax}
  s.email = %q{}
  s.extra_rdoc_files = ["README.rdoc", "lib/active_factory.rb", "lib/generators/active_factory/install/USAGE", "lib/generators/active_factory/install/install_generator.rb", "lib/generators/active_factory/install/templates/active_factory.rb", "lib/generators/active_factory/install/templates/define_factories.rb", "lib/hash_struct.rb"]
  s.files = ["MIT-LICENSE", "README.rdoc", "Rakefile", "init.rb", "lib/active_factory.rb", "lib/generators/active_factory/install/USAGE", "lib/generators/active_factory/install/install_generator.rb", "lib/generators/active_factory/install/templates/active_factory.rb", "lib/generators/active_factory/install/templates/define_factories.rb", "lib/hash_struct.rb", "spec/active_factory_define_spec.rb", "spec/active_factory_spec.rb", "spec/active_record_environment_spec.rb", "spec/define_lib_factories.rb", "spec/spec_helper.rb", "spec/support/active_record_environment.rb", "Manifest", "active_factory.gemspec"]
  s.homepage = %q{http://github.com/tarasevich/active_factory}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Active_factory", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{active_factory}
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Fixtures replacement with sweet syntax}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
