require_relative 'lib/type_balancer/rails/version'

Gem::Specification.new do |spec|
  spec.name = 'type_balancer-rails'
  spec.version = TypeBalancer::Rails::VERSION
  spec.authors = ['Carl Mercier']
  spec.email = ['carl@carlmercier.com']

  spec.summary = 'A Rails gem for efficient database query optimization and caching'
  spec.description = 'TypeBalancer Rails provides tools for optimizing database queries, implementing efficient caching strategies, and managing database load in Rails applications.'
  spec.homepage = 'https://github.com/carl-mercier/type_balancer-rails'
  spec.license = 'MIT'

  spec.files = Dir['{lib}/**/*', 'LICENSE', 'README.md']
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.7.0'

  spec.add_dependency 'rails', '>= 6.0'
  spec.add_dependency 'redis', '>= 4.0'

  spec.add_development_dependency 'database_cleaner-active_record'
  spec.add_development_dependency 'mock_redis'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'timecop'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
