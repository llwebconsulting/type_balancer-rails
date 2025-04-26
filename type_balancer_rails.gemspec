# frozen_string_literal: true

require_relative 'lib/type_balancer/rails/version'

Gem::Specification.new do |spec|
  spec.name = 'type_balancer_rails'
  spec.version = TypeBalancer::Rails::VERSION
  spec.authors = ['Carl Smith']
  spec.email = ['carl@llwebconsulting.com']

  spec.summary = 'Rails integration for type_balancer'
  spec.description = 'Provides Rails integration for the type_balancer gem'
  spec.homepage = 'https://github.com/llwebconsulting/type_balancer-rails'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?('bin/', 'test/', 'spec/', 'features/', '.git', '.circleci', 'appveyor', 'Gemfile')
    end
  end
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'activerecord', '~> 7.0'
  spec.add_dependency 'activesupport', '~> 7.0'
  spec.add_dependency 'type_balancer', '~> 0.1', '>= 0.1.0'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
