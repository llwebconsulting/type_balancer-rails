# Removing Old Configuration Classes: Plan and Checklist

## Context
- This gem has not been published and has no external users.
- We have consolidated configuration into the new `TypeBalancer::Rails::Config` namespace.
- Old configuration classes and their specs can be safely removed, but we must ensure all references are updated or removed to avoid confusion and errors.

## Mapping Old Configuration Functionality to New Locations

| Old File/Class/Method                                      | Responsibility / Description                | New Location / Replacement                | Notes/Changes                |
|------------------------------------------------------------|---------------------------------------------|-------------------------------------------|------------------------------|
| `TypeBalancer::Rails::Configuration`                       | Main config class, registry, pagination     | `TypeBalancer::Rails::Config::Configuration` / `BaseConfiguration` | Split into base/runtime/unified |
| `TypeBalancer::Rails::Configuration::StorageStrategyRegistry` | Storage strategy registration/lookup        | `TypeBalancer::Rails::Config::StrategyManager` | Renamed, interface updated   |
| `TypeBalancer::Rails::Configuration::PaginationConfig`     | Pagination settings                        | `TypeBalancer::Rails::Config::PaginationConfig` | Moved, interface may differ  |
| `TypeBalancer::Rails::Configuration::CacheConfig`          | Cache settings                             | `TypeBalancer::Rails::Config::CacheConfig` | Moved, interface may differ  |
| `TypeBalancer::Rails::Configuration::RedisConfig`          | Redis settings                             | `TypeBalancer::Rails::Config::RedisConfig` | Moved, interface may differ  |
| `TypeBalancer::Rails::Configuration#reset!`                | Reset all config                           | `TypeBalancer::Rails::Config::Configuration#reset!` | Logic may be split           |
| `require 'type_balancer/rails/configuration'`              | Loads old config                           | `require 'type_balancer/rails/config/configuration'` | Update require path           |

**How to use this mapping:**
- If you encounter a missing method or class after removal, check this table to see where it has moved.
- If a test or feature breaks, use this as a reference to update the code to the new location/interface.
- If you need to revert, you know exactly what to restore and where.

## Step-by-Step Plan

### 1. Identify Old Classes and Files to Remove
- `lib/type_balancer/rails/configuration.rb` (old main configuration)
- `lib/type_balancer/rails/configuration/`
  - `cache_config.rb`
  - `redis_config.rb`
  - `pagination_config.rb`
  - `storage_strategy_registry.rb`
- Any other files in `lib/type_balancer/rails/configuration/`
- Specs:
  - `spec/type_balancer/rails/configuration/`
    - `cache_config_spec.rb`
    - `redis_config_spec.rb`
    - `pagination_config_spec.rb`
    - `storage_strategy_registry_spec.rb`

### 2. Find and Update/Remove All References
- **Code:**
  - Update any code referencing `TypeBalancer::Rails::Configuration` or its nested classes to use the new `TypeBalancer::Rails::Config` equivalents.
  - Update or remove any `require 'type_balancer/rails/configuration'` or similar lines.
- **Specs:**
  - Remove or update specs that reference the old configuration classes.
- **Test Helpers:**
  - Remove any references in `spec/unit_helper.rb` or other helpers.
- **Gem Entrypoint:**
  - Remove `require 'type_balancer/rails/configuration'` from `lib/type_balancer-rails.rb`.

### 3. Checklist for Safe Removal
- [ ] All references to `TypeBalancer::Rails::Configuration` and its nested classes are removed or updated.
- [ ] All `require` statements for old configuration files are removed.
- [ ] All specs for old configuration classes are removed.
- [ ] The old configuration files and their directory are deleted.
- [ ] All tests pass after removal.

### 4. How to Verify
- Run a full-text search for `TypeBalancer::Rails::Configuration` and its nested classes (e.g., `PaginationConfig`, `StorageStrategyRegistry`, `CacheConfig`, `RedisConfig`).
- Run a full-text search for `require 'type_balancer/rails/configuration'` and similar requires.
- Run the test suite to ensure nothing is broken.

### 5. If You Get Stuck
- If a reference remains, update it to use the new config class or remove it if obsolete.
- If a test fails, check if it was testing old config logic and either update or remove as appropriate.

### 6. Final Step
- Once all old files and references are removed and tests pass, commit the changes with a clear message (e.g., "Remove legacy configuration classes and specs").

---

**This plan ensures a clean break from the old configuration system and prevents confusion or accidental reintroduction of legacy code.**
