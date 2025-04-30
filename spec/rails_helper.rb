require 'database_cleaner/active_record'

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
    DatabaseCleaner.strategy = :transaction
  end

  config.around do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  config.fixture_path = Rails.root.join('test/fixtures').to_s
  config.use_transactional_fixtures = true
  config.include ActiveRecord::TestFixtures
end
