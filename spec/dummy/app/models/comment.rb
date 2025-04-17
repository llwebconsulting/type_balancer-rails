# frozen_string_literal: true

class Comment < ApplicationRecord
  include TypeBalancer::Rails::Pagination

  belongs_to :post

  validates :content, presence: true
  validates :author_name, presence: true

  # Enable cursor-based pagination with composite ordering
  cursor_paginate order: {
    post_id: :asc,
    created_at: :desc,
    id: :desc
  }

  # Scope for testing nested resources
  scope :for_post, ->(post_id) { where(post_id: post_id) }
  scope :recent, -> { order(created_at: :desc) }

  # Cache configuration for testing
  after_commit :invalidate_cache

  private

  def invalidate_cache
    Rails.cache.delete("comment/#{id}")
    Rails.cache.delete("post/#{post_id}/comments")
  end
end
