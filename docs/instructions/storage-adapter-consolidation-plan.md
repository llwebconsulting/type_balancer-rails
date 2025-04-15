# Storage Adapter Consolidation Plan

## Current State

We have multiple StorageAdapter classes:
1. `ConfigStorageAdapter` in `lib/type_balancer/rails/config/storage_adapter.rb` (target implementation)
2. `StorageAdapter` in `lib/type_balancer/rails/config.rb`
3. `StorageAdapter` in `lib/type_balancer/rails/configuration.rb`
4. `StrategyStorageAdapter` in `lib/type_balancer/rails/strategies/storage_adapter.rb`

## Method Analysis Required

Before proceeding with any changes, we need to analyze the method signatures and implementations across all adapter classes. Special attention to:

1. `delete` method
   - Which adapters implement it
   - Parameter signatures (named vs positional)
   - Return values and error handling

2. `exists?` method
   - Which adapters implement it
   - Parameter signatures (named vs positional)
   - Return values and error handling

3. Any other unique methods in the adapters we plan to remove

## Method Analysis Results

### ConfigStorageAdapter (Target Implementation)
```ruby
# Methods to analyze:
- configure_redis(client)
- configure_cache(store)
- validate!
- store(key:, value:, ttl: nil)
- fetch(key)
- clear
```

### StorageAdapter (config.rb)
```ruby
# Methods to analyze:
- initialize(redis_client = nil, cache_store = nil)
- store(key:, value:, ttl: nil)
- fetch(key)
- delete(key)
- clear
- validate!
- redis_enabled? (private)
```

### StorageAdapter (configuration.rb)
```ruby
# Methods to analyze:
- initialize
- adapter (attr_accessor)
```

### StrategyStorageAdapter (strategies/storage_adapter.rb)
```ruby
# Methods to analyze:
- initialize(strategy_manager)
- store(key:, value:, ttl: nil)
- fetch(key)
- delete(key)
- clear
- exists?(key)
- validate!
```

## Implementation Plan

### Phase 1: Update ConfigStorageAdapter
1. Add missing methods:
   ```ruby
   def delete(key)
     if redis_enabled?
       redis_client.del(key)
     else
       cache_store.delete(key)
     end
   end

   def exists?(key:)
     if redis_enabled?
       redis_client.exists?(key)
     else
       cache_store.exist?(key)
     end
   end
   ```

2. Update method signatures for consistency:
   - All methods that take a key should use named parameters
   - All methods should handle both Redis and cache cases
   - All methods should have consistent error handling

### Phase 2: Update Test Doubles
1. Update remaining test files to use ConfigStorageAdapter:
   - `cache_invalidation_spec.rb`
   - `position_manager_spec.rb`
   - `active_record_extension_spec.rb`
2. Run tests after each file change
3. Document any issues encountered

### Phase 3: Remove Redundant Adapters
Only after all tests pass with ConfigStorageAdapter:
1. Remove StorageAdapter from `config.rb`
2. Remove StorageAdapter from `configuration.rb`
3. Remove StrategyStorageAdapter from `strategies/storage_adapter.rb`

## Safety Measures

1. Commit after each successful change
2. Run full test suite after each phase
3. Document any test failures or issues
4. Keep track of all method signatures for compatibility

## Rollback Plan

If issues are encountered:
1. Git reset to last known good state
2. Document the specific issue
3. Revise the plan based on findings

## Success Criteria

1. All tests passing
2. No duplicate adapter classes
3. All necessary methods implemented in ConfigStorageAdapter
4. Consistent method signatures across the codebase
5. No regressions in functionality 