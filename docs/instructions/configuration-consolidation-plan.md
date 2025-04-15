# Configuration Class Consolidation Plan

## Current State

We currently have two `Configuration` classes with overlapping responsibilities:

1. `TypeBalancer::Rails::Configuration` in `configuration.rb`:
   - Manages configuration settings
   - Handles storage strategy registration
   - Controls pagination configuration
   - Contains a nested `StorageAdapter` class
   - Focuses on configuration state management

2. `TypeBalancer::Rails::Core::Configuration` in `core.rb`:
   - Handles validation and configuration of Redis and cache
   - Uses `ConfigStorageAdapter` and `StrategyManager`
   - Implements strict validation rules
   - Focuses on runtime configuration

## Issues

1. Duplicate class names causing potential confusion
2. Overlapping responsibilities
3. Inconsistent approach to storage adapter management
4. Potential naming conflicts
5. Scattered configuration logic

## Consolidation Plan

### Phase 1: Preparation

1. Create a new namespace for configuration:
   ```ruby
   module TypeBalancer
     module Rails
       module Config
         # Configuration classes will live here
       end
     end
   end
   ```

2. Rename existing classes:
   - `TypeBalancer::Rails::Configuration` -> `TypeBalancer::Rails::Config::BaseConfiguration`
   - `TypeBalancer::Rails::Core::Configuration` -> `TypeBalancer::Rails::Config::RuntimeConfiguration`

### Phase 2: Feature Consolidation

1. Create a new unified `Configuration` class that:
   - Inherits core functionality from `BaseConfiguration`
   - Incorporates validation from `RuntimeConfiguration`
   - Uses a single storage adapter approach
   - Maintains a clear separation of concerns

2. Merge common functionality:
   - Redis configuration methods
   - Cache configuration methods
   - Storage strategy registration
   - Validation rules

### Phase 3: Implementation

1. Create the new unified class structure:
   ```ruby
   module TypeBalancer
     module Rails
       module Config
         class Configuration
           include ValidationBehavior
           include StorageManagement
           include PaginationConfig
           
           def initialize
             # Initialize with merged functionality
           end
           
           # ... merged methods ...
         end
       end
     end
   end
   ```

2. Extract shared behaviors into modules:
   - `ValidationBehavior`
   - `StorageManagement`
   - `PaginationConfig`

3. Update all references to use the new unified class

### Phase 4: Testing

1. Create comprehensive tests for the new unified class
2. Ensure all existing functionality is preserved
3. Verify that validation rules work as expected
4. Test integration with other components

### Phase 5: Migration

1. Deprecate old classes:
   ```ruby
   module TypeBalancer
     module Rails
       class Configuration
         def self.inherited(*)
           warn "[DEPRECATION] #{name} is deprecated. Use TypeBalancer::Rails::Config::Configuration instead."
           super
         end
       end
     end
   end
   ```

2. Update documentation to reflect new structure
3. Provide migration guide for users

### Phase 6: Cleanup

1. Remove deprecated classes after appropriate deprecation period
2. Clean up any remaining references
3. Update all related documentation

## Safety Measures

1. Version bump required
2. Deprecation warnings before removal
3. Comprehensive test coverage
4. Migration guide for users
5. Backward compatibility layer if needed

## Success Criteria

1. Single, well-organized configuration class
2. Clear separation of concerns
3. Improved test coverage
4. No duplicate class names
5. Clear documentation
6. Successful migration of existing users

## Timeline

1. Phase 1-2: 1-2 days
2. Phase 3: 2-3 days
3. Phase 4: 1-2 days
4. Phase 5: 1 day
5. Phase 6: 1 day

Total estimated time: 6-9 days

## Rollback Plan

1. Keep old class files until confirmed stable
2. Maintain version compatibility
3. Document rollback procedures
4. Keep backup of all modified files 