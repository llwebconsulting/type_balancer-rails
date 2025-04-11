# frozen_string_literal: true

class Post < ActiveRecord::Base
  include TypeBalancer::Rails::CacheInvalidation
end 