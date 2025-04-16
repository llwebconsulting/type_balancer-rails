# frozen_string_literal: true

module TestHelpers
  def create_post_class
    Class.new do
      def self.table_name
        'posts'
      end

      def self.column_names
        ['id', 'title', 'media_type']
      end

      def self.model_name
        ActiveModel::Name.new(self, nil, 'Post')
      end

      def self.primary_key
        'id'
      end

      def self.base_class
        self
      end
    end
  end

  def create_post_double(attributes = {})
    post_class = create_post_class
    instance_double(post_class,
                    id: attributes[:id] || 1,
                    class: post_class,
                    title: attributes[:title] || 'Test Post',
                    media_type: attributes[:media_type] || 'video',
                    cache_key_with_version: attributes[:cache_key_with_version] || 'posts/1-123',
                    to_param: (attributes[:id] || 1).to_s,
                    persisted?: true)
  end

  def create_relation_double(post_class = create_post_class)
    double = instance_double(ActiveRecord::Relation)
    allow(double).to receive_messages(
      klass: post_class,
      table_name: post_class.table_name,
      column_names: post_class.column_names,
      count: 2000,
      cache_key_with_version: 'posts/all-123',
      none: double,
      where: double,
      order: double,
      to_sql: 'SELECT * FROM posts',
      model_name: post_class.model_name,
      base_class: post_class,
      primary_key: 'id'
    )
    double
  end
end

RSpec.configure do |config|
  config.include TestHelpers
end
