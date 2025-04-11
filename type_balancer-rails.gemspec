# frozen_string_literal: true

require_relative "lib/type_balancer/rails/version"

Gem::Specification.new do |spec|
  spec.name = "type_balancer-rails"
  spec.version = TypeBalancer::Rails::VERSION
  spec.authors = ["Carl Smith"]
  spec.email = ["carl@llwebconsulting.com"]

  spec.summary = "Rails integration for the type_balancer gem"
  spec.description = "Extends the type_balancer gem with Rails-specific features, including ActiveRecord integration, efficient caching, and pagination support"
  spec.homepage = "https://github.com/llwebconsulting/type_balancer-rails"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/llwebconsulting/type_balancer-rails"
  spec.metadata["changelog_uri"] = "https://github.com/llwebconsulting/type_balancer-rails/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "type_balancer", "~> 0.1.1"
  spec.add_dependency "rails", ">= 7.0", "< 9.0"
  spec.add_dependency "activerecord", ">= 7.0", "< 9.0"
  spec.add_dependency "activesupport", ">= 7.0", "< 9.0"

  spec.add_development_dependency "rspec-rails", "~> 6.1"
  spec.add_development_dependency "sqlite3", "~> 1.7"
  spec.add_development_dependency "rubocop", "~> 1.62"
  spec.add_development_dependency "rubocop-rails", "~> 2.24"
  spec.add_development_dependency "rubocop-rspec", "~> 2.27"
  spec.add_development_dependency "yard", "~> 0.9.36"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
