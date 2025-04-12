# frozen_string_literal: true

require_relative 'lib/type_balancer/rails/version'

Gem::Specification.new do |spec|
  spec.name = 'type_balancer-rails'
  spec.version = TypeBalancer::Rails::VERSION
  spec.authors = ['Carl Zulauf']
  spec.email = ['carl@linkleaf.com']

  spec.summary = 'Rails integration for the type_balancer gem'
  spec.description = 'Extends type_balancer with Rails-specific features for ActiveRecord integration, caching, and pagination'
  spec.homepage = 'https://github.com/carlzulauf/type_balancer-rails'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = Dir.glob(%w[
                          LICENSE.txt
                          README.md
                          CHANGELOG.md
                          lib/**/*.rb
                          sig/**/*.rbs
                        ])
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'rails', '>= 6.1'
  spec.add_dependency 'redis', '~> 5.0'
  spec.add_dependency 'type_balancer', '~> 0.1.1'

  # Development dependencies
  spec.add_development_dependency 'bundler-audit', '~> 0.9.1'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec-rails', '~> 6.1'
  spec.add_development_dependency 'rubocop', '~> 1.21'
  spec.add_development_dependency 'rubocop-rails', '~> 2.24'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.27'
  spec.add_development_dependency 'simplecov', '~> 0.22.0'
  spec.add_development_dependency 'simplecov-cobertura', '~> 2.1'
  spec.add_development_dependency 'sqlite3', '~> 1.7', '>= 1.7.3'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
