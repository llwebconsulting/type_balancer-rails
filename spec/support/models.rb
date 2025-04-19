# frozen_string_literal: true

require 'active_record'

class ApplicationRecord
  def self.inherited(base)
    super
    base.extend(ClassMethods)
  end

  module ClassMethods
    def find(*)
      new
    end

    def where(*)
      []
    end

    def find_by(*)
      nil
    end

    def after_commit(method_name = nil, &block)
      @after_commit_callbacks ||= []
      @after_commit_callbacks << (method_name || block)
    end
  end

  def save(*)
    self.class.instance_variable_get(:@after_commit_callbacks)&.each do |callback|
      if callback.is_a?(Symbol)
        send(callback)
      else
        instance_exec(&callback)
      end
    end
    true
  end

  def destroy(*)
    save
  end
end

class Article < ApplicationRecord
  include TypeBalancer::Rails::CacheInvalidation

  def self.type_field
    :media_type
  end

  def media_type
    'article'
  end
end
