module TypeBalancer
  module Rails
    module Strategies
      class RedisStrategy < BaseStrategy
        def initialize(redis: nil, ttl: 1.hour)
          @redis = redis || Redis.new
          @ttl = ttl
        end

        def fetch_page(scope, page: 1, page_size: 20)
          cache_key = "type_balancer:#{scope.cache_key_with_version}"
          
          balanced_ids = @redis.get(cache_key) || calculate_and_cache(scope, cache_key)
          balanced_ids = JSON.parse(balanced_ids)
          
          start_idx = (page - 1) * page_size
          page_ids = balanced_ids[start_idx, page_size]
          
          records = scope.where(id: page_ids)
          ordered_records = records.index_by(&:id).values_at(*page_ids).compact
          
          [ordered_records, has_next_page?(balanced_ids, start_idx, page_size)]
        end

        def next_page_token(result)
          result.last # Returns boolean indicating if there's a next page
        end

        private

        def calculate_and_cache(scope, cache_key)
          balanced = TypeBalancer.balance(scope.to_a, type_field: scope.type_field)
          balanced_ids = balanced.map(&:id)
          @redis.setex(cache_key, @ttl, balanced_ids.to_json)
          balanced_ids.to_json
        end

        def has_next_page?(balanced_ids, start_idx, page_size)
          start_idx + page_size < balanced_ids.size
        end
      end
    end
  end
end 