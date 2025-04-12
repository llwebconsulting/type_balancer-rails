# TypeBalancer Rails Refactoring Plan

## Current Structure Analysis

### Configuration Class Issues
- Currently handles multiple responsibilities:
  - Configuration settings management
  - Strategy registration
  - Redis client management
  - Container management
- Violates Single Responsibility Principle
- Makes testing and maintenance difficult

### BalancedCollectionQuery Issues
- Handles too many concerns:
  - Query building
  - Caching logic
  - Position calculation
  - Position storage
  - Pagination
- Complex testing requirements
- Difficult to extend or modify

### Strategy Classes Issues
- Generally well-structured but has some concerns:
  - Mixed storage and caching concerns
  - Direct dependency on Rails.cache
  - Could benefit from better separation of concerns

## Proposed Refactoring Structure

### Phase 1: Configuration Separation

```ruby
module TypeBalancer::Rails
  class Configuration
    # Pure configuration settings
    attr_accessor :cache_enabled, :cache_ttl, :redis_ttl, 
                 :cursor_buffer_multiplier,
                 :background_processing_threshold
                 
    def initialize
      set_defaults
    end
    
    private
    
    def set_defaults
      # Only default value setting
    end
  end

  class StrategyManager
    # Strategy registration and resolution
    def register(name, strategy)
    def resolve(name)
    def available_strategies
    def reset!
  end

  class StorageAdapter
    # Storage backend configuration
    def configure_redis(client)
    def configure_cache(store)
    def reset!
  end
end
```

### Phase 2: Query Layer Separation

```ruby
module TypeBalancer::Rails
  class BalancedQuery
    # Pure query building
    def initialize(scope, options = {})
    def build
    def with_options(options)
  end

  class PositionManager
    # Position management
    def calculate(collection)
    def store(positions)
    def fetch(key)
    def invalidate(key)
  end

  class PaginationService
    # Pagination logic
    def initialize(collection, options = {})
    def paginate(page, per_page)
    def next_page?
    def total_pages
  end
end
```

### Phase 3: Storage Strategy Refinement

```ruby
module TypeBalancer::Rails
  module Storage
    class BaseStorage
      # Core storage functionality
      def store(key, value)
      def fetch(key)
      def delete(key)
      def clear
    end

    class CacheDecorator
      # Caching capability
      def initialize(storage)
      def store(key, value, ttl = nil)
      def fetch(key)
    end

    class RedisStorage < BaseStorage
      # Redis-specific implementation
    end

    class CursorStorage < BaseStorage
      # Cursor-specific implementation
    end
  end
end
```

## Implementation Plan

### Step 1: Create New Structure
1. Create new files for separated concerns
   - Configuration classes
   - Query layer classes
   - Storage classes
2. Implement basic interfaces
   - Define method signatures
   - Add documentation
3. Add tests for new classes
   - Unit tests for each class
   - Integration tests for key workflows

### Step 2: Migration
1. Gradually move functionality to new classes
   - Start with configuration separation
   - Move to query layer
   - Finally, refactor storage
2. Update existing code to use new structure
   - Update references
   - Maintain existing API
3. Maintain backward compatibility
   - Add deprecation warnings
   - Provide migration guide

### Step 3: Clean Up
1. Remove deprecated code
   - After migration period
   - When all clients updated
2. Update documentation
   - Update README
   - Update API documentation
   - Add migration guides
3. Ensure test coverage
   - Check coverage metrics
   - Add missing tests
   - Update integration tests

### Step 4: Integration
1. Update ActiveRecord extension
   - Use new query builder
   - Update configuration hooks
2. Refactor job processing
   - Use new position manager
   - Update background jobs
3. Update configuration interface
   - Simplify configuration
   - Add validation

## Testing Strategy

### Unit Tests
- Each new class should have comprehensive unit tests
- Mock dependencies appropriately
- Test edge cases and error conditions

### Integration Tests
- Test key workflows end-to-end
- Verify backward compatibility
- Test with different Rails versions

### Performance Tests
- Benchmark key operations
- Compare with previous implementation
- Verify no performance regression

## Timeline and Priorities

### High Priority
1. Configuration separation
2. Query layer separation
3. Basic test coverage

### Medium Priority
1. Storage strategy refinement
2. Migration support
3. Documentation updates

### Low Priority
1. Performance optimization
2. Advanced features
3. Nice-to-have improvements

## Success Metrics

1. Code Quality
   - Improved test coverage
   - Reduced complexity metrics
   - Better separation of concerns

2. Maintainability
   - Easier to add new features
   - Simpler testing
   - Clear documentation

3. Performance
   - No regression in key operations
   - Improved memory usage
   - Better cache utilization

## Risks and Mitigation

### Risks
1. Breaking changes for existing users
2. Performance regression
3. Missing edge cases

### Mitigation
1. Maintain compatibility layer
2. Comprehensive performance testing
3. Extensive testing with real-world data 