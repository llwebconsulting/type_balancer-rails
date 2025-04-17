# frozen_string_literal: true

class Post < ApplicationRecord
  include TypeBalancer::Rails::Pagination

  has_many :comments, dependent: :destroy

  validates :title, presence: true
  validates :content, presence: true

  # Enable cursor-based pagination with default ordering
  cursor_paginate order: { created_at: :desc, id: :desc }

  # Scope for testing complex queries
  scope :published, -> { where(published: true) }
  scope :by_author, ->(author_id) { where(author_id: author_id) }

  # Cache configuration for testing
  after_commit :invalidate_cache

  private

  def invalidate_cache
    Rails.cache.delete("post/#{id}")
  end
end
