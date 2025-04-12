# frozen_string_literal: true

module TypeBalancer
  module Rails
    module Strategies
      class Strategy
        def initialize(collection_query)
          @collection_query = collection_query
        end

        def execute
          raise NotImplementedError, "#{self.class} must implement #execute"
        end

        protected

        attr_reader :collection_query
      end
    end
  end
end
