# frozen_string_literal: true

RSpec.shared_context "active_record_test_helpers" do
  let(:model_class) do
    Class.new do
      def self.model_name
        ActiveModel::Name.new(self, nil, "Post")
      end

      def self.where(conditions = {})
        all
      end

      def self.limit(count)
        all
      end

      def self.offset(count)
        all
      end

      def self.all
        new
      end

      def self.find_each(&block)
        [new].each(&block)
      end

      def id
        1
      end

      def cache_key_with_version
        "posts/1-123456789"
      end

      def after_commit(*args)
        # Simulate ActiveRecord callback registration
      end
    end
  end

  let(:relation) do
    instance_double(
      "ActiveRecord::Relation",
      model_name: model_class.model_name,
      where: nil,
      limit: nil,
      offset: nil,
      to_a: []
    )
  end

  before do
    # Common ActiveRecord mocks
    allow(ActiveRecord::Base).to receive(:include).and_return(true)
    allow(Rails.cache).to receive(:fetch).and_yield
    allow(Rails.cache).to receive(:delete_matched)
  end
end 