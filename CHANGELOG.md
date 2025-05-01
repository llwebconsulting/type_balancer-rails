## [Unreleased]

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
