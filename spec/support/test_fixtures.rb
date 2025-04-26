# frozen_string_literal: true

module TestFixtures
  module_function

  def create_mock_relation(records = sample_records)
    relation = double('ActiveRecord::Relation')
    allow(relation).to receive(:is_a?).with(ActiveRecord::Relation).and_return(true)
    allow(relation).to receive(:to_a).and_return(records)
    relation
  end

  def create_paginated_relation(page: 1, per_page: 10)
    relation = create_mock_relation(pagination_records)

    # Calculate the correct slice based on pagination params
    start_idx = (page - 1) * per_page
    end_idx = start_idx + per_page
    paginated_records = pagination_records[start_idx...end_idx] || []

    allow(relation).to receive_messages(limit: relation, offset: relation, count: pagination_records.length,
                                        to_a: paginated_records)
    relation
  end

  def sample_records
    [
      mock_record(id: 1, media_type: 'video'),
      mock_record(id: 2, media_type: 'article'),
      mock_record(id: 3, media_type: 'video'),
      mock_record(id: 4, media_type: 'image'),
      mock_record(id: 5, media_type: 'article')
    ]
  end

  def pagination_records
    @pagination_records ||= begin
      # Create 50 records with a specific distribution:
      # - 40% articles (20 records)
      # - 40% images (20 records)
      # - 20% videos (10 records) - fewer videos but weighted higher for visibility
      records = []
      records << add_records([], 1, 'article', 20)
      records << add_records([], 21, 'image', 20)
      records << add_records([], 41, 'video', 10)

      # Shuffle the records to simulate real-world randomness
      records.shuffle(random: Random.new(42)) # Fixed seed for reproducibility
    end
  end

  def add_records(records, starting_point, content_type, iterations)
    iterations.times do |i|
      records << mock_record(
        id: starting_point + i,
        media_type: content_type,
        created_at: Time.now - (50 - i).hours
      )
    end
    records
  end

  def mock_record(attributes)
    record = double('Record')
    attributes.each do |key, value|
      allow(record).to receive(key).and_return(value)
    end
    record
  end

  def mock_post_class
    Class.new do
      include ActiveModel::Model
      include TypeBalancer::Rails::CollectionMethods
      attr_accessor :id, :media_type, :created_at

      def self.table_name = 'posts'
      def self.primary_key = 'id'

      def initialize(attributes = {})
        super
        @id = attributes[:id]
        @media_type = attributes[:media_type]
        @created_at = attributes[:created_at]
      end
    end
  end
end
