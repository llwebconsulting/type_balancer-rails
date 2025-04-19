# frozen_string_literal: true

class Post < ApplicationRecord
  include TypeBalancer::Rails::Pagination
  include TypeBalancer::Rails::CacheInvalidation

  validates :title, presence: true
  validates :content, presence: true

  # Scope for testing complex queries
  scope :published, -> { where(published: true) }
  scope :by_author, ->(author_id) { where(author_id: author_id) }

  # Cache configuration for testing
  after_commit :invalidate_cache

  def self.type_field
    :title
  end

  private

  def invalidate_cache
    Rails.cache.delete("post/#{id}")
  end
end
