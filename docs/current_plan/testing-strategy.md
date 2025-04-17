# Testing Strategy

## Core Principles

1. **Integration Tests are Source of Truth**
   - Integration tests define the expected real-world behavior
   - When conflicts arise, integration test expectations take precedence
   - Code changes driven by integration tests are considered "correct behavior"
   - Integration tests validate the complete feature workflow

2. **Unit Tests Follow Integration**
   - Unit tests must adapt to match integration-proven behavior
   - Never modify code to make unit tests pass at the expense of integration tests
   - Unit tests verify implementation details of integration-proven features
   - Unit tests provide comprehensive coverage of code paths

3. **Test Isolation and Dependencies**
   - Integration tests use SQLite in-memory database
   - All tests use mock Redis and memory store for caching
   - External services are always mocked, never real connections
   - Dependencies are clearly defined and managed through test helpers
   - Clear separation between test types prevents cycles

4. **Development Workflow**
   - Complete unit test coverage before starting integration tests
   - When working on integration tests, ignore unit test failures
   - Only fix unit tests after integration tests are passing
   - Never toggle between fixing integration and unit tests simultaneously
   - Test dependencies are properly managed

## Directory Structure
```ruby
spec/
  integration/     # Integration tests are separate and take precedence
  unit/           # Unit tests organized by component
  support/        # Shared test helpers and configurations
  dummy/          # Rails test application
```

## Test Types and Responsibilities

### Integration Tests
- Test full feature workflows
- Use dummy Rails application
- Mock external services (Redis, cache)
- Define expected behavior
- Drive code changes
- Verify real-world scenarios

### Unit Tests
- Provide comprehensive coverage
- Test component internals
- Use doubles and mocks
- Adapt to integration-proven behavior
- Never test private methods directly
- Cover edge cases and error paths

## Working with Tests

### When Writing Integration Tests
1. Focus solely on integration tests
2. Make code changes to pass integration tests
3. Ignore unit test failures
4. Document integration test expectations clearly
5. Use realistic test data and scenarios

### After Integration Tests Pass
1. Review failed unit tests
2. Update unit tests to match new behavior
3. Never change working code to fix unit tests
4. Add new unit tests for edge cases
5. Ensure all mocks match real behavior

### Test Dependencies
- Use `mock_redis` consistently
- Use memory store for caching
- Use SQLite for integration database
- Mock all external services
- Keep dependencies isolated

## Cross-reference
This document complements `integration-testing.md`, which provides detailed implementation plans for integration tests. While that document focuses on "what" to test, this strategy document outlines "how" we approach testing and resolve conflicts between test types. 