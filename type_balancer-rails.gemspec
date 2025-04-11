# frozen_string_literal: true

require_relative 'lib/type_balancer/rails/version'

Gem::Specification.new do |spec|
  spec.name = 'type_balancer-rails'
  spec.version = TypeBalancer::Rails::VERSION
  spec.authors = ['Carl Smith']
  spec.email = ['carl@llwebconsulting.com']

  spec.summary = 'Rails integration for the type_balancer gem'
  spec.description = 'Provides Rails integration for the type_balancer gem with ActiveRecord support and efficient pagination strategies'
  spec.homepage = 'https://github.com/llwebconsulting/type_balancer-rails'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = Dir.glob("{lib,sig}/**/*") + %w[README.md LICENSE.txt CHANGELOG.md]
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'type_balancer', '~> 0.1.1'
  spec.add_dependency 'activesupport', '>= 7.0'
  spec.add_dependency 'activerecord', '>= 7.0'

  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 1.21'
  spec.add_development_dependency 'redis', '~> 5.0'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
