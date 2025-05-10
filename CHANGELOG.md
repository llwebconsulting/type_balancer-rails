## [0.2.8] - 2025-05-10

- **Rails-style configuration block:**
  You can now configure TypeBalancer Rails in an initializer using:
  ```ruby
  TypeBalancer::Rails.configure do |config|
    config.cache_adapter = TypeBalancer::Rails::CacheAdapter.new
    config.cache_expiry_seconds = 600
  end
  ```
  Direct assignment is still supported for backward compatibility.

- **Per-request cache control:**
  `balance_by_type` now accepts:
  - `expires_in:` (override cache expiry for a single call)
  - `cache_reset:` (force cache refresh for a single call)

- **Global cache expiry configuration:**
  Set the default cache expiry for all balanced queries via `TypeBalancer::Rails.cache_expiry_seconds`.

- **Cache clearing:**
  Use `TypeBalancer::Rails.clear_cache!` to clear all cached balanced results (e.g., from a console or admin task).

### Changed
- **Caching and pagination are always enabled** for performance and reliability.
- **Cache keys are now isolated** per model and type field, preventing cross-contamination.

## [0.2.7] - 2025-05-04

- Always-on pagination: Results from `balance_by_type` are now always paginated for performance (default: 20 per page, page 1). There is no option to disable pagination.
- Added support for `per_page` and `page` options to control result size and page.
- Added support for `expires_in` option to override the default cache expiration (default: 10 minutes) per call.
- Cache adapter is now a first-class, configurable component (`TypeBalancer::Rails.cache_adapter`).
- Improved documentation and architecture overview to reflect new pagination and caching behavior.
- RuboCop and test stability improvements.

## [0.2.6] - 2025-05-01

- Updated type_balancer dependency to ~> 0.2.1 for improved performance

## [0.2.5] - 2025-04-30

- Updated type_balancer dependency to ~> 0.2.0 for improved performance and better position calculations

## [0.2.4] - 2025-04-29

- Fixed critical ActiveRecord extension compatibility issue with `all` method
- Improved ActiveRecord integration by properly maintaining method signatures
- Enhanced test coverage for ActiveRecord core functionality
- Ensured compatibility with internal ActiveRecord operations like `reload`

## [0.2.3] - 2025-04-29

- Fixed issue with returning correctly balance items
- Fixed RuboCop configuration and addressed violations
- Reorganized CI workflow to properly handle example app tests as integration suite
- Improved test organization and coverage
- Added proper RuboCop configuration for example app with inheritance handling

## [0.2.2] - 2025-04-27

- Version sync release: Ensures the gem version and git tag match after a previous mismatch (v0.2.1 tag pointed to v0.2.0 code). No code changes from 0.2.1.

## [0.2.0] - 2025-04-27

- Refactored `balance_by_type` to only send `id` and type field to TypeBalancer for efficiency and clarity
- Ensured robust ordering of returned records based on balanced ids (supports flat and nested balancer output)
- Full TDD coverage for all new and refactored logic (unit and integration tests)
- Added GitHub Actions workflow for automated gem releases on tag push

## [0.1.0] - 2025-04-26

- Initial release
