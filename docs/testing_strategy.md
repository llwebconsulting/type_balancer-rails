# Testing Strategy for TypeBalancer Rails

## Core Principles

1. **Bottom-Up Testing Approach**
   - Start with leaf classes (no dependencies)
   - Progress to branch classes (some dependencies)
   - Finally test trunk classes (core functionality)

2. **Mocking Strategy**
   - Only mock classes that have already been tested
   - Use strict mocking to ensure interface compliance
   - Mock all external services (Redis, Rails cache, etc.)
   - For ActiveRecord mocking, use the provided test doubles in `spec/support/active_record_doubles.rb` and `spec/support/active_record_mocks.rb`
   - Add new mock behaviors to these support files when needed rather than creating one-off mocks

3. **Test Organization**
   - One describe block per class
   - Nested describes for methods/contexts
   - Clear, descriptive test names
   - Organized setup with well-named let blocks

4. **Coverage Goals**
   - 100% coverage of public methods
   - Edge cases and error conditions covered
   - Thread safety tested where relevant
   - No direct testing of private methods

5. **Test-Driven Development Flow**
   - Complete one test file at a time
   - Write all necessary tests for the current class/module
   - Ensure all tests in the file pass before moving to the next file
   - Never start testing a new class until current class tests are passing
   - If tests fail, focus on fixing the current file before moving on
   - Progress through the dependency tree systematically

## Implementation Order

### Phase 1: Leaf Classes
- Strategy classes (Redis, Memory)
- Error classes
- Configuration value objects
- Utility classes

### Phase 2: Branch Classes
- StrategyManager
- StorageAdapter
- Configuration validators

### Phase 3: Core Classes
- Core configuration
- Rails integration
- Public API methods

## Testing Guidelines

1. **Each Test Should**
   - Test one specific behavior
   - Have clear setup and expectations
   - Use meaningful test data
   - Follow arrange-act-assert pattern

2. **Mocking Guidelines**
   - Use provided ActiveRecord test doubles (`ar_instance_double`, `ar_class_double`, `ar_relation_double`, `ar_test_class`) for consistent AR mocking
   - Extend shared mock behaviors in support files rather than duplicating in individual tests
   - Use instance_double for strict interface checking
   - Mock only what's necessary
   - Avoid stubbing non-existent methods
   - Verify mock expectations

3. **Naming Conventions**
   - Use descriptive test names
   - Follow "it should..." pattern
   - Group related tests in contexts
   - Use clear variable names

4. **Test Organization**
   ```ruby
   RSpec.describe SomeClass do
     describe '#method_name' do
       context 'when some condition' do
         it 'should do something specific' do
           # test code
         end
       end
     end
   end
   ```

## ActiveRecord Test Helpers

The gem provides two complementary approaches for testing ActiveRecord-related code:

### 1. Test Doubles (`active_record_doubles.rb`)
Use these when you need to:
- Mock ActiveRecord behavior without actual implementation
- Verify method calls and responses
- Test interface compliance
- Need predefined responses for common AR methods

Available helpers:
```ruby
# Mock an AR instance with common methods stubbed
let(:user) { ar_instance_double("User") }

# Mock an AR class with common class methods stubbed
let(:user_class) { ar_class_double("User") }

# Mock an AR relation with chainable scopes
let(:users_relation) { ar_relation_double("User") }

# Create a basic test class with AR modules included
let(:test_model) { ar_test_class("TestModel") }
```

### 2. Test Classes (`active_record_test_classes.rb`)
Use these when you need:
- Real ActiveRecord-like behavior (callbacks, naming, etc.)
- To test module inclusion
- To work with actual record arrays
- To test behavior that depends on ActiveRecord's class hierarchy

Available helpers:
```ruby
# Create a full mock AR class with naming and callbacks
let(:user_class) { mock_model_class("User") }

# Create a relation that works with actual records
let(:relation) { mock_active_record_relation(user_class, [user1, user2]) }
```

### When to Use Each

1. Use Test Doubles (`active_record_doubles.rb`) when:
   - You just need to verify method calls
   - You want strict interface checking
   - You need simple predefined responses
   - You're testing code that uses AR as a dependency

2. Use Test Classes (`active_record_test_classes.rb`) when:
   - You need to test module inclusion
   - You need real callback behavior
   - You're working with collections of actual records
   - You need AR's class hierarchy features

### Extending the Helpers

When new ActiveRecord behaviors need to be mocked:
1. First check if the behavior exists in either support file
2. Decide which approach better fits your needs:
   - Interface verification → add to `active_record_doubles.rb`
   - Actual behavior implementation → add to `active_record_test_classes.rb`
3. Document the new behavior in the file's comments
4. Use the shared mock in your tests

## Quality Checks

- Run full test suite before checking coverage
- Ensure no test is testing private methods
- Verify thread safety in concurrent scenarios
- Check for test isolation (no dependencies between tests)

## Next Steps

1. Remove all existing tests
2. Map out class dependencies
3. Identify leaf classes
4. Begin with simplest leaf class
5. Progress systematically through dependency tree, one file at a time 