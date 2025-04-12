# frozen_string_literal: true

module TestHelpers
  def create_post_class
    Class.new do
      def self.table_name
        "posts"
      end

      def self.column_names
        %w[id title media_type]
      end

      def self.model_name
        ActiveModel::Name.new(self, nil, "Post")
      end

      def self.primary_key
        "id"
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
      title: attributes[:title] || "Test Post",
      media_type: attributes[:media_type] || "video",
      cache_key_with_version: attributes[:cache_key_with_version] || "posts/1-123",
      to_param: (attributes[:id] || 1).to_s,
      persisted?: true
    )
  end

  def create_relation_double(post_class = create_post_class)
    double = instance_double(ActiveRecord::Relation)
    allow(double).to receive(:klass).and_return(post_class)
    allow(double).to receive(:table_name).and_return(post_class.table_name)
    allow(double).to receive(:column_names).and_return(post_class.column_names)
    allow(double).to receive(:count).and_return(2000)
    allow(double).to receive(:cache_key_with_version).and_return('posts/all-123')
    allow(double).to receive(:none).and_return(double)
    allow(double).to receive(:where).and_return(double)
    allow(double).to receive(:order).and_return(double)
    allow(double).to receive(:to_sql).and_return('SELECT * FROM posts')
    allow(double).to receive(:model_name).and_return(post_class.model_name)
    allow(double).to receive(:base_class).and_return(post_class)
    allow(double).to receive(:primary_key).and_return('id')
    double
  end
end

RSpec.configure do |config|
  config.include TestHelpers
end
