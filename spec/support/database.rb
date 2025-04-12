# frozen_string_literal: true

# Configure ActiveRecord to use SQLite3 in memory for tests
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

# Create schema
ActiveRecord::Schema.define do
  create_table :posts, force: true do |t|
    t.string :title
    t.string :media_type
    t.boolean :published, default: false
    t.timestamps
  end

  create_table :articles, force: true do |t|
    t.string :title
    t.string :category
    t.boolean :featured, default: false
    t.timestamps
  end
end

# Define test models
class Post < ActiveRecord::Base
  MEDIA_TYPES = %w[video image text].freeze

  validates :title, presence: true
  validates :media_type, inclusion: { in: MEDIA_TYPES }
end

class Article < ActiveRecord::Base
  CATEGORIES = %w[news opinion tech].freeze

  validates :title, presence: true
  validates :category, inclusion: { in: CATEGORIES }
end

RSpec.configure do |config|
  config.before(:suite) do
    # Ensure database is clean before running suite
    Post.delete_all
    Article.delete_all
  end

  config.after do
    # Clean up after each test
    Post.delete_all
    Article.delete_all
  end
end
