# TypeBalancer Rails Gem: Architecture Overview

## 1. Project Summary

TypeBalancer Rails is a Ruby gem designed to provide advanced balancing and ordering capabilities for ActiveRecord collections in Rails applications. Its primary feature is the ability to balance records by a specified type, ensuring even distribution and flexible pagination of heterogeneous data sets. The gem is intended for use in Rails projects that require sophisticated content or resource balancing, such as feeds, dashboards, or content aggregators.

---

## 2. Architecture & Dependencies

### High-Level Architecture
- **Core Module:** The gem's core logic is implemented under `lib/type_balancer/rails/`, with extensions for ActiveRecord and integration with Rails via a Railtie.
- **ActiveRecord Integration:** The gem extends ActiveRecord models and relations to provide the `balance_by_type` method, which can be called on any model or relation.
- **Rails Integration:** A Railtie ensures the gem is loaded and configured automatically in Rails environments.
- **Generators:** The gem provides a Rails generator for easy installation and configuration.

### Key Dependencies
- **active_support**: Used for concerns, core extensions, and Rails integration.
- **active_record**: The gem extends ActiveRecord models and relations.
- **type_balancer**: The core balancing logic is delegated to the `type_balancer` gem (see below).
- **Rails (optional)**: For automatic integration via Railtie and generator support.

### About the TypeBalancer Gem

TypeBalancer is a Ruby gem that provides advanced algorithms for distributing items of different types evenly across a sequence. Its primary use case is to ensure that, in collections where certain types (e.g., articles, images, videos) are overrepresented, the output is balanced so that all types are fairly and optimally spaced. This is especially useful for content feeds, e-commerce listings, news aggregators, and recommendation systems.

**Key Features:**
- Balances collections by type, ensuring optimal spacing and respecting type ratios.
- Uses a sophisticated sliding window strategy by default, with support for custom window sizes and type orderings.
- Extensible strategy system for future balancing algorithms.
- Thread-safe, memory-efficient, and suitable for real-time processing of collections up to 10,000 items.
- No external dependencies and high performance across Ruby versions.

**Core API:**
- `TypeBalancer.balance(items, type_field: :type, strategy: :sliding_window, window_size: 10, type_order: [...])`  
  Balances an array of items by the specified type field, using the chosen strategy and options.
- `TypeBalancer.calculate_positions(total_count:, ratio:, available_items: [...])`  
  Calculates optimal positions for a given type or subset within a sequence.

**Integration with Rails:**
- The TypeBalancer Rails gem acts as a façade and adapter, exposing TypeBalancer's balancing logic as an easy-to-use method (`balance_by_type`) on ActiveRecord relations and models.
- This allows Rails developers to leverage advanced balancing in queries and collections with minimal setup.

---

## 3. Class & Module Documentation

### `TypeBalancer::Rails::CollectionMethods`
- **Location:** `lib/type_balancer/rails/collection_methods.rb`
- **Purpose:**
  - Provides the `balance_by_type` method for ActiveRecord::Relation, enabling balanced selection and ordering of records by a type field.
  - Handles pagination and result ordering.
- **Dependencies:**
  - Depends on `TypeBalancer.balance` for core balancing logic.
  - Expects to be included in ActiveRecord::Relation.
- **Patterns:**
  - Adapter/Extension pattern for ActiveRecord::Relation.

### `TypeBalancer::Rails::ActiveRecordExtension`
- **Location:** `/Users/carl/gems/type_balancer-rails/lib/type_balancer/rails/active_record_extension.rb`
- **Purpose:**
  - Provides a concern to extend ActiveRecord models with type balancing configuration and class-level `balance_by_type` method.
  - Ensures `CollectionMethods` is included in ActiveRecord::Relation.
- **Dependencies:**
  - `ActiveSupport::Concern`, `ActiveRecord::Relation`, `TypeBalancer::Rails::CollectionMethods`.
- **Patterns:**
  - Rails Concern, Extension.

### `TypeBalancer::Rails::Railtie`
- **Location:** `/Users/carl/gems/type_balancer-rails/lib/type_balancer/rails/railtie.rb`
- **Purpose:**
  - Integrates the gem with Rails, ensuring the ActiveRecord extension is loaded automatically.
- **Dependencies:**
  - `Rails::Railtie`, `ActiveSupport.on_load(:active_record)`.
- **Patterns:**
  - Railtie for Rails integration.

### `TypeBalancer::Rails::VERSION`
- **Location:** `/Users/carl/gems/type_balancer-rails/lib/type_balancer/rails/version.rb`
- **Purpose:**
  - Defines the gem's version constant.
- **Dependencies:** None.

### `TypeBalancer::Rails` (Module)
- **Location:** `/Users/carl/gems/type_balancer-rails/lib/type_balancer/rails.rb`
- **Purpose:**
  - Loads and wires up all Rails-specific extensions and dependencies for the gem.
- **Dependencies:**
  - `active_support`, `active_record`, `TypeBalancer::Rails::ActiveRecordExtension`, `TypeBalancer::Rails::CollectionMethods`.

### Main Entry File
- **Location:** `/Users/carl/gems/type_balancer-rails/lib/type_balancer_rails.rb`
- **Purpose:**
  - Loads all required dependencies and sets up the gem for use in a Rails environment.
  - Loads the Railtie if Rails is present.

### Generator: `TypeBalancer::Generators::InstallGenerator`
- **Location:** `/Users/carl/gems/type_balancer-rails/lib/generators/type_balancer/install/install_generator.rb`
- **Purpose:**
  - Provides a Rails generator for installing TypeBalancer configuration into a Rails app.
- **Dependencies:**
  - Rails generator framework.
- **Patterns:**
  - Generator pattern for Rails setup.

---

## 4. Testing Strategy

- **Unit Tests:**
  - Located in `/Users/carl/gems/type_balancer-rails/spec/`.
  - Organized by feature/module (e.g., `spec/type_balancer/rails/collection_methods_spec.rb`).
  - Do **not** use a database; all database and dependency interactions are strictly mocked or stubbed.
  - Shared contexts and helpers are provided in `spec/support/` (e.g., `test_helpers.rb`, `test_fixtures.rb`).
  - Test models for mocking are in `spec/support/models/`.

- **Integration Tests:**
  - Located in the example Rails app under `/Users/carl/gems/type_balancer-rails/example/`.
  - Example app contains its own `spec/` directory with feature, controller, and model specs.
  - Integration tests use a real database and Rails stack to verify end-to-end behavior.
  - Example app includes its own Gemfile and configuration for isolated testing.

- **Testing Practices:**
  - Unit tests focus on class responsibilities and use mocking for all external dependencies.
  - Integration tests are only created in the example app and are not run as part of the main gem's unit test suite.
  - No direct tests of private methods; only public interfaces are tested.
  - RSpec is used as the test framework throughout.
  - RuboCop is used for code style enforcement (`.rubocop.yml` present in both root and example app).
  - CI and test runner setup is inferred from the presence of `.rspec`, `.rspec_status`, and Rakefile.

- **Interesting/Unique Practices:**
  - Strict separation of unit and integration tests, with clear boundaries and no database usage in unit tests.
  - Use of shared contexts and helpers to DRY up test setup.
  - Example app serves as a living integration testbed for real-world Rails usage.

---

## 5. Additional Notes
- All file paths in this documentation are absolute, per project standards.
- The gem follows SOLID principles and Rails best practices, with minimal monkey-patching and clear extension points.
- For more details, see the README and inline code comments. 