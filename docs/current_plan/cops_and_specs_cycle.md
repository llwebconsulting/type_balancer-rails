# Plan for Addressing RuboCop Violations and Maintaining Test Integrity

## Current State
- Tests: All passing
- RuboCop violations: Higher than our previous best state (when we had only 6 violations)
- Main issue: Fixing one aspect (cops/tests) is causing regressions in the other

## Methodical Approach

### 1. Establish Baseline
1. Run and document all current RuboCop violations
2. Categorize violations by:
   - Auto-correctable vs manual fixes needed
   - Type of violation (Style, Metrics, RSpec, etc.)
   - File/component affected
3. Save this baseline in a tracking file

### 2. Fix Violations in Small Batches
1. Select a small batch of related violations (max 3-4 at a time)
2. Before fixing:
   - Document current state (violations and passing tests)
3. Apply fixes:
   - For auto-correctable: Run with -a for just the selected files
   - For manual: Make minimal necessary changes
4. After each fix:
   - Run RuboCop to verify fix AND check no new violations
   - Run full test suite
   - If tests fail, revert and try different approach
5. Only commit when both tests pass AND no new violations introduced

### 3. Test Maintenance
1. If test fixes are needed:
   - Document why the test is now failing
   - Verify if test expectations need updating vs implementation bug
   - Make minimal changes to fix tests
2. After test fixes:
   - Run RuboCop to verify no new violations introduced
   - If new violations appear, revert and try different approach

### 4. Progress Tracking
1. Maintain a progress file with:
   - ✓ Fixed violations
   - ⚠ In progress
   - ❌ Still to address
2. Update after each successful batch
3. Note any patterns of violations that tend to cascade into other issues

### 5. Priority Order
1. Start with auto-correctable violations in non-test files
2. Then address test-specific violations
3. Leave complex metrics violations for last
4. Group related violations together

### 6. Rules for Changes
1. Never introduce new violations while fixing others
2. Keep changes minimal and focused
3. If a fix causes cascading issues, revert and add to "needs design discussion"
4. Document any patterns that cause test/cop conflicts

## Next Steps
1. Run RuboCop and create baseline violation report
2. Identify first batch of violations to address
3. Create tracking file for progress
4. Begin with first batch following the above cycle

## Success Criteria
- All tests passing
- RuboCop violations at or below our previous best (6 violations)
- No new violations introduced during fixes
- Clear documentation of any remaining issues that need broader discussion 