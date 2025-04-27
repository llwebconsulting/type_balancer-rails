## [Unreleased]

## [0.2.0] - 2024-04-27

- Refactored `balance_by_type` to only send `id` and type field to TypeBalancer for efficiency and clarity
- Ensured robust ordering of returned records based on balanced ids (supports flat and nested balancer output)
- Full TDD coverage for all new and refactored logic (unit and integration tests)
- Added GitHub Actions workflow for automated gem releases on tag push

## [0.1.0] - 2025-04-10

- Initial release
