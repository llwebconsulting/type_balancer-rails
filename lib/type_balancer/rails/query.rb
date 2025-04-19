# frozen_string_literal: true

require_relative 'query/query_builder'
require_relative 'query/type_field_resolver'
require_relative 'query/balanced_query'
require_relative 'query/pagination_service'
require_relative 'query/position_manager'
require_relative 'query/cursor_service'
require 'digest/md5'

module TypeBalancer
  module Rails
    # Query module that ties together all query-related components
    module Query
      def self.new(scope, options = {})
        QueryWrapper.new(scope, options)
      end

      # Internal class to handle query execution
      class QueryWrapper
        attr_reader :scope, :options

        def initialize(scope, options = {})
          @scope = scope
          @options = options
          @balanced_query = BalancedQuery.new(scope, options)
        end

        def execute
          result = @balanced_query.build
          cache_key = generate_cache_key(result)

          if cache_enabled?
            cached_result = ::Rails.cache.read(cache_key)
            return cached_result if cached_result

            result_array = result.to_a
            ::Rails.cache.write(cache_key, result_array, expires_in: cache_ttl)
            result_array
          else
            result.to_a
          end
        end

        private

        def generate_cache_key(result)
          components = [
            'type_balancer_query',
            result.to_sql,
            @options.to_json,
            cache_ttl.to_s
          ]
          Digest::MD5.hexdigest(components.join('|'))
        end

        def cache_ttl
          TypeBalancer::Rails.configuration.cache_ttl || 1.hour
        end

        def cache_enabled?
          TypeBalancer::Rails.configuration.enable_cache || false
        end
      end
    end
  end
end
