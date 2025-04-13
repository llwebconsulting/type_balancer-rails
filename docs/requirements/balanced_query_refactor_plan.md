# BalancedQuery Refactor Plan

## Context

This refactor is part of Phase 2 (Complex Interactions) of the testing strategy outlined in `docs/testing_strategy.md`. The current implementation of `BalancedQuery` has been identified as having multiple issues that need to be addressed:

1. Multiple implementations causing namespace confusion
2. Circular dependencies
3. Violation of Single Responsibility Principle
4. Testing difficulties due to complex dependencies

## Refactor Steps

### Step 1: Clean Up Duplicate Implementations

- Delete duplicate implementations:
  - Remove `lib/type_balancer/rails/balanced_query.rb`
  - Remove `lib/type_balancer/rails/balanced_collection_query.rb`
- Keep only `lib/type_balancer/rails/query/balanced_query.rb`
- Update all references to use the correct namespace
- Remove existing tests that will be invalidated by this refactor

### Step 2: Component Separation

Break down the monolithic `BalancedQuery` into focused components:

1. **QueryBuilder**
   - Responsibility: Basic query construction
   - Methods:
     - `apply_order(order)`
     - `apply_conditions(conditions)`
   - Dependencies: None (potential leaf node)

2. **TypeFieldResolver**
   - Responsibility: Type field handling
   - Methods:
     - `resolve(explicit_field = nil)`
   - Dependencies: None (potential leaf node)

3. **BalancedQuery**
   - Responsibility: High-level coordination
   - Dependencies:
     - QueryBuilder
     - TypeFieldResolver

### Step 3: Testing Strategy

Following our leaf-first testing approach:

1. Identify Leaf Nodes
   - Analyze new components after refactor
   - Identify which components have no dependencies
   - Prioritize testing these components first

2. Testing Order
   - Start with leaf node components (QueryBuilder, TypeFieldResolver)
   - Only move to testing BalancedQuery after leaf nodes are fully tested
   - Write tests for one class at a time
   - Ensure all tests pass before moving to the next class

3. Test Coverage Requirements
   - Each component must have comprehensive unit tests
   - Mock all dependencies appropriately
   - Ensure edge cases are covered
   - Maintain high test coverage

## Success Criteria

1. No duplicate implementations
2. Clear separation of responsibilities
3. No circular dependencies
4. All components have comprehensive tests
5. All tests passing
6. High test coverage
7. Clear and documented component interfaces

## Implementation Notes

- Follow SOLID principles throughout the refactor
- Document all public interfaces
- Update dependency injection where needed
- Ensure backward compatibility or document breaking changes
- Keep commit history clean and logical
- Update documentation as needed

## Dependencies on Testing Strategy

This refactor directly supports Phase 2 of our testing strategy by:
1. Breaking down complex components into testable units
2. Identifying and prioritizing leaf nodes
3. Enabling proper dependency mocking
4. Following the leaf-first testing approach

## Next Steps

1. Delete current BalancedQuery tests
2. Remove duplicate implementations
3. Create new component files
4. Identify leaf nodes
5. Begin testing leaf nodes
6. Implement remaining components
7. Update documentation 