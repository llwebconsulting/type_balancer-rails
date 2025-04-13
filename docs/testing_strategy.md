# Testing Strategy for Complex Components

## Core Principles

1. **Leaf-First Testing Approach**
   - Only mock components that have already been thoroughly tested
   - Build testing from the bottom up, starting with leaf nodes
   - Document dependencies between components to ensure proper testing order

2. **Dependency Mapping**
   - Before testing a component, map out all its dependencies
   - Classify dependencies as:
     - Leaf nodes (can be mocked if tested)
     - Complex dependencies (must be tested first)
     - External services (always mocked)

3. **Mock Strategy**
   ```ruby
   # Example of proper mocking approach
   let(:tested_leaf_node) { instance_double("TypeBalancer::Rails::LeafComponent") }
   before do
     # Only mock methods that are actually tested in LeafComponent's specs
     allow(tested_leaf_node).to receive(:verified_method).and_return(expected_value)
   end
   ```

   ### ActiveRecord Test Doubles

   We have two systems for mocking ActiveRecord behavior:

   1. **ActiveRecord Doubles** (`spec/support/active_record_doubles.rb`)
      ```ruby
      # Provides lightweight, controlled doubles
      ar_class_double      # For mocking AR class behavior
      ar_instance_double   # For mocking AR instance behavior
      ar_relation_double   # For mocking AR::Relation behavior
      ```
      Use these when you need simple method stubbing and interface verification.

   2. **ActiveRecord Mocks** (`spec/support/active_record_mocks.rb`)
      ```ruby
      # Provides more complete AR-like behavior
      mock_model_class     # Creates a full mock AR class with naming, callbacks
      mock_active_record_relation  # Creates relation with actual enumerable behavior
      ```
      Use these when you need actual ActiveRecord-like behavior (callbacks, naming, etc.)

   **Important**: Choose one approach per test file to avoid conflicts. Do not mix these approaches
   as they may create conflicting method stubs or behavior.

4. **Test Organization**
   - Group tests by component responsibility
   - Maintain clear separation between unit and future integration tests
   - Follow the testing pyramid:
     - Many unit tests
     - Fewer integration tests (when added later)
     - Minimal end-to-end tests (when needed)

## Testing Order Guidelines

1. **Phase 1: Core Components** (Completed)
   - ✓ Memory Strategy
   - ✓ Configuration Facade
   - ✓ Storage Strategy Registry

2. **Phase 2: Complex Interactions**
   - Cache Invalidation (depends on tested storage adapters)
   - Background Processing (depends on tested collection handling)
   - Query Services (depends on tested pagination)

3. **Phase 3: Integration Points**
   - Rails initialization hooks
   - ActiveRecord extensions
   - Cache store integrations

## Best Practices

1. **Coverage Requirements**
   - Maintain high unit test coverage (target: >90%)
   - Focus on branch coverage for complex logic
   - Document any intentionally uncovered code

2. **Test Isolation**
   ```ruby
   # Good: Testing single responsibility
   describe "#process_collection" do
     context "when using tested storage adapter" do
       let(:storage) { instance_double("TestedStorageAdapter") }
       it "processes items correctly" do
         # Test only the processing logic
       end
     end
   end
   ```

3. **Documentation**
   - Document test dependencies in the spec file header
   - Note which components must be tested first
   - Explain mocking decisions

## Avoiding Common Pitfalls

1. **Circular Dependencies**
   - Map component relationships before writing tests
   - Break circular dependencies through proper abstraction
   - Document dependency resolution strategies

2. **Test Pollution**
   - Reset global state between tests
   - Use RSpec metadata for shared context
   - Avoid sharing state between examples

3. **False Positives**
   - Test edge cases explicitly
   - Verify mock expectations
   - Test failure conditions

## Implementation Checklist

Before testing a component:
- [ ] Map all dependencies
- [ ] Verify leaf nodes are tested
- [ ] Document mocking strategy
- [ ] Review edge cases
- [ ] Plan error scenarios

## Future Considerations

1. **Integration Testing**
   - Will be added after unit test completion
   - Focus on critical paths
   - Test different Rails configurations

2. **Performance Testing**
   - Measure impact on Rails boot time
   - Profile memory usage
   - Test caching strategies

3. **Compatibility Testing**
   - Multiple Rails versions
   - Different Ruby versions
   - Various database adapters 