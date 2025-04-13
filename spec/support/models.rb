require 'active_record'

class Post < ActiveRecord::Base
  include TypeBalancer::Rails::CacheInvalidation

  def self.type_field
    :media_type
  end

  def media_type
    'post'
  end
end

class Article < ActiveRecord::Base
  include TypeBalancer::Rails::CacheInvalidation

  def self.type_field
    :media_type
  end

  def media_type
    'article'
  end
end
