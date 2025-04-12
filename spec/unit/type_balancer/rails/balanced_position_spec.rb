# frozen_string_literal: true

require "unit_helper"

RSpec.describe TypeBalancer::Rails::BalancedPosition do
  let(:post_class) do
    Class.new do
      def self.name
        "Post"
      end

      def self.table_name
        "posts"
      end
    end
  end

  let(:post) do
    instance_double(post_class,
      id: 1,
      class: post_class,
      title: "Test Post",
      media_type: "video",
      cache_key_with_version: "posts/1-123"
    )
  end

  let(:cache_key) { "type_balancer/posts/test_collection" }

  describe "validations" do
    let(:relation_class) do
      Class.new do
        def self.exists?(*args)
          false
        end
      end
    end

    subject(:position) do
      position = described_class.new(
        record: post,
        position: 1,
        cache_key: cache_key,
        type_field: "media_type"
      )
      
      # Mock the validation methods
      allow(position).to receive(:validate_unique_position)
      allow(position).to receive(:validate_unique_record)
      
      position
    end

    before do
      # Mock ActiveRecord::Base behavior
      allow(described_class).to receive(:validates_presence_of)
      allow(described_class).to receive(:belongs_to)
      allow(described_class).to receive(:validate)
    end

    it "is valid with valid attributes" do
      expect(position).to be_valid
    end

    it "requires a record" do
      position.record = nil
      expect(position).not_to be_valid
    end

    it "requires a position" do
      position.position = nil
      expect(position).not_to be_valid
    end

    it "requires a cache_key" do
      position.cache_key = nil
      expect(position).not_to be_valid
    end

    it "enforces unique position within cache_key" do
      allow(described_class).to receive(:exists?).with(cache_key: cache_key, position: 1).and_return(true)
      position.send(:validate_unique_position)
      expect(position.errors[:position]).to include("has already been taken")
    end

    it "enforces unique record within cache_key" do
      allow(described_class).to receive(:exists?).with(cache_key: cache_key, record: post).and_return(true)
      position.send(:validate_unique_record)
      expect(position.errors[:record]).to include("has already been taken")
    end
  end

  describe ".for_collection" do
    let(:posts) do
      3.times.map do |i|
        instance_double(post_class,
          id: i + 1,
          class: post_class,
          title: "Post #{i}",
          media_type: "video",
          cache_key_with_version: "posts/#{i+1}-123"
        )
      end
    end

    let(:positions) do
      posts.each_with_index.map do |post, i|
        instance_double(described_class,
          record: post,
          position: i + 1,
          cache_key: cache_key,
          valid?: true
        )
      end
    end

    before do
      relation = instance_double("ActiveRecord::Relation")
      allow(described_class).to receive(:where).with(cache_key: cache_key).and_return(relation)
      allow(relation).to receive(:order).with(:position).and_return(positions)
    end

    it "returns positions for a cache key in order" do
      result = described_class.for_collection(cache_key)
      expect(result.map(&:position)).to eq([1, 2, 3])
    end

    it "excludes positions from other cache keys" do
      result = described_class.for_collection(cache_key)
      expect(result.count).to eq(3)
    end
  end

  describe ".table_definition" do
    let(:table_definition) { instance_double("ActiveRecord::ConnectionAdapters::TableDefinition") }
    
    before do
      allow(table_definition).to receive(:references)
      allow(table_definition).to receive(:integer)
      allow(table_definition).to receive(:string)
      allow(table_definition).to receive(:timestamps)
      allow(table_definition).to receive(:index)
    end

    it "defines the expected columns and indexes" do
      definition = described_class.table_definition
      definition.call(table_definition)

      expect(table_definition).to have_received(:references).with(:record, polymorphic: true, null: false)
      expect(table_definition).to have_received(:integer).with(:position, null: false)
      expect(table_definition).to have_received(:string).with(:cache_key, null: false)
      expect(table_definition).to have_received(:string).with(:type_field)
      expect(table_definition).to have_received(:timestamps)
      expect(table_definition).to have_received(:index).with([:cache_key, :position], unique: true)
      expect(table_definition).to have_received(:index).with([:record_type, :record_id, :cache_key], unique: true)
    end
  end
end 