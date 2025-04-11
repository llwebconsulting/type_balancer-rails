# frozen_string_literal: true

require "unit_helper"

RSpec.describe TypeBalancer::Rails::CacheInvalidation do
  let(:dummy_class) do
    Class.new do
      include TypeBalancer::Rails::CacheInvalidation
      
      def self.table_name
        "posts"
      end

      def cache_key_with_version
        "posts/123-20240321"
      end
    end
  end

  let(:record) { dummy_class.new }

  describe "#invalidate_balance_cache" do
    it "deletes the cache entries for the record type" do
      expect(Rails.cache).to receive(:delete_matched).with("type_balancer/posts/*")
      record.send(:invalidate_balance_cache)
    end

    it "deletes balanced positions for the record" do
      positions_relation = instance_double("ActiveRecord::Relation")
      
      expect(TypeBalancer::Rails::BalancedPosition).to receive(:for_record)
        .with(record)
        .and_return(positions_relation)
      
      expect(positions_relation).to receive(:delete_all)
      
      record.send(:invalidate_balance_cache)
    end
  end
end 