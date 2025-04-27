namespace :dev do
  desc 'Load test fixtures into the development database (WARNING: this will delete all existing records in posts and contents!)'
  task load_fixtures: :environment do
    require 'active_record/fixtures'
    puts 'Deleting all Posts and Contents...'
    Post.delete_all
    Content.delete_all
    puts 'Loading fixtures from test/fixtures...'
    ActiveRecord::FixtureSet.create_fixtures('test/fixtures', ['posts', 'contents'])
    puts 'Fixtures loaded!'
  end
end
