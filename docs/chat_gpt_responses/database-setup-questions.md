Below is a proposed re‑ordering and tweak of your two key files so that Rails will pick up your dummy app’s database.yml automatically, and you can drop the manual in‑memory connection. All changes are commented with # ← changed next to them.

# spec/spec_helper.rb
```
# frozen_string_literal: true

require 'bundler/setup'
require 'simplecov'
require 'simplecov-cobertura'
require 'timecop'
require 'active_record'
require 'yaml'                             # ← changed: load YAML to read database.yml

# Configure SimpleCov
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/lib/type_balancer/rails/version'
  enable_coverage :branch

  add_group 'Core',        'lib/type_balancer/rails'
  add_group 'ActiveRecord','lib/type_balancer/rails/active_record'
  add_group 'Storage',     'lib/type_balancer/rails/storage'
  add_group 'Query',       'lib/type_balancer/rails/query'
  add_group 'Config',      'lib/type_balancer/rails/config'

  formatter SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::CoberturaFormatter
  ])
end

ENV['RAILS_ENV'] ||= 'test'                # ← changed: ensure we pick up test env

# → **Load the dummy Rails app _first_**, so it configures ActiveRecord for us
require File.expand_path('dummy/config/environment', __dir__)  # ← changed

# → Now that Rails has loaded, point ActiveRecord at the dummy’s database.yml
ActiveRecord::Base.configurations = YAML.load_file(
  File.expand_path('dummy/config/database.yml', __dir__)
)                                            # ← changed
ActiveRecord::Base.establish_connection(Rails.env.to_sym)  # ← changed

# You can now drop the manual in‐memory call:
# ActiveRecord::Base.establish_connection(
#   adapter: 'sqlite3', database: ':memory:'
# )

# Load our gem
require 'type_balancer/rails'

# Initialize TypeBalancer
TypeBalancer::Rails.initialize!

# Load all support files
Dir[File.join(File.dirname(__FILE__), 'support', '**', '*.rb')].each { |f| require f }

# Configure RSpec
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.warnings = true
  config.order = :random
  Kernel.srand config.seed

  # → Load schema only _after_ connection is established
  config.before(:suite) do
    ActiveRecord::Schema.define(version: 20_240_315_000_001) do
      create_table :posts, force: :cascade do |t|
        t.string  :title,   null: false
        t.text    :content
        t.timestamps null: false
        t.index :created_at
        t.index :title
      end
    end
  end

  # wrap each example in a transaction
  config.around do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end

  config.before(:suite) do
    Rails.cache = ActiveSupport::Cache::MemoryStore.new(namespace: 'test')
  end

  config.before do
    TypeBalancer::Rails.reset!
    TypeBalancer::Rails.instance_variable_set(:@storage_adapter, nil)
  end
end
```

# spec/dummy/config/application.rb
```
# frozen_string_literal: true

require 'rails'
require 'active_record/railtie'
require 'active_support/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'active_job/railtie'

# Add the lib directory to the load path
$LOAD_PATH.unshift File.expand_path('../../../lib', __dir__)
require 'type_balancer_rails'

module Dummy
  class Application < Rails::Application
    # ensure Rails.root points at spec/dummy
    config.root = File.expand_path('..', __dir__)              # ← changed

    # tell Rails where to find database.yml
    config.paths['config/database'] = Rails.root.join('config', 'database.yml')  # ← changed

    config.load_defaults Rails::VERSION::STRING.to_f

    # ... rest of your config untouched ...
  end
end
```

1. Order of operations
	1.	Set RAILS_ENV, require the dummy app’s environment.rb (so Rails loads all railties, sets up ActiveRecord::Base.configurations from your database.yml, and defines Rails.root).
	2.	Re‑point ActiveRecord (if you need to override or explicitly load configurations) by reading your dummy’s database.yml and calling establish_connection.
	3.	Load or run your schema/migrations (in a before(:suite) block or via ActiveRecord::Migration.maintain_test_schema!).
	4.	Initialize your gem, caches, etc., and then run each example in a transaction.

2. Dummy app configuration
	•	Ensure config.root is actually spec/dummy, not the gem root.
	•	Tell Rails exactly where to look for database.yml via config.paths['config/database'].
	•	With that in place, require 'dummy/config/environment' will load your in‑memory test database automatically.

3. Engine‑testing considerations
	•	Include rspec-rails if you need any of its Rails helpers (rails_helper.rb style).
	•	If your engine has migrations, append them to ActiveRecord::Migrator.migrations_paths so you can load them.
	•	Use ActiveRecord::Migration.maintain_test_schema! or load your engine’s db/schema.rb into the dummy app.

4. Managing test DB state
	•	Transactional examples (around with rollback) are fastest under SQLite in‑memory.
	•	If you move to a DB that doesn’t support nested‑transactions, switch to DatabaseCleaner with the truncation strategy in a before(:suite) / after(:each) setup.
	•	Always reset any global or cache state between tests (TypeBalancer::Rails.reset!).

With those reordered files and these pointers, Rails will find your database.yml and spin up the in‑memory database before you define your schema and run your integration specs. Let me know if you still get the “Cannot load database configuration” error or if anything else crops up!