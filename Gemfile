# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in type_balancer_rails.gemspec
gemspec

# Use local path for type_balancer during development
gem 'type_balancer', '~> 0.1.2'

# Development dependencies
gem 'action-cable-testing', '~> 0.6.1'
gem 'bundler-audit', '~> 0.9.1'
gem 'rake', '~> 13.0'
gem 'rspec', '~> 3.13'
gem 'rspec-rails', '~> 6.1'
gem 'rubocop', '~> 1.62'
gem 'rubocop-rails', '~> 2.24'
gem 'rubocop-rspec', '~> 2.27'
gem 'simplecov', '~> 0.22.0'
gem 'simplecov-cobertura', '~> 2.1' # XML format for CodeCov
gem 'sqlite3', '~> 2.1' # Update to required version

group :development, :test do
  gem 'database_cleaner', '~> 2.0'
  gem 'debug', '>= 1.0.0'
  gem 'pry', '~> 0.14.2'
  gem 'pry-byebug'
end
