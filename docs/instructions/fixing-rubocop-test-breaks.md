# Instructions for Fixing Tests After Rubocop Fixes

## Context
These instructions are specifically for fixing test failures that occurred after implementing Rubocop fixes. This is a unique situation because:
- The original code was working and tests were passing
- Changes were purely stylistic/convention-based
- The main branch contains working reference code
- No architectural changes were intended

## General Approach

1. **One Test at a Time**
   - Focus on fixing one failing test at a time
   - Run only that specific test while fixing
   - Once fixed, run the full suite to ensure no regressions

2. **Reference Main Branch**
   - Keep the main branch code open as reference
   - Compare the working test with the broken test
   - Look for subtle changes that Rubocop might have introduced

3. **Common Rubocop-Related Test Breaks**
   - Check for renamed variables that weren't updated in the tests
   - Look for changed string quotes (single vs double) affecting test expectations
   - Verify array/hash syntax changes haven't affected test data
   - Check for whitespace/indentation changes affecting heredocs or multi-line strings
   - Verify method argument formatting hasn't changed method signatures

4. **Debugging Process**
   - Use `puts` debugging strategically
   - Compare object inspection output between main and current branch
   - Focus on data structure differences rather than implementation
   - Check for changes in return value formatting

5. **When Stuck**
   - Git blame to find the specific Rubocop fix that caused the break
   - Review the Rubocop rule that was fixed
   - Consider if the test needs updating vs the implementation

## Important Notes

- Do not make architectural changes while fixing these tests
- If you find non-Rubocop related issues, document them for later
- Keep commits focused on test fixes only
- Add comments explaining any non-obvious test modifications

## StorageAdapter Issue
This issue requires careful handling to prevent agent crashes and ensure all references are properly updated:

1. **Branch Creation and Setup**
   ```bash
   git checkout main
   git pull origin main
   git checkout -b fix/storage-adapter-naming
   ```

2. **Identify StorageAdapter Classes**
   - Search for all StorageAdapter class definitions
   - Document their locations and current namespaces
   - Create a list of all files referencing each StorageAdapter class
   - Note: Do not attempt to fix all instances at once

3. **Incremental Renaming Strategy**
   - Work on one StorageAdapter class at a time
   - Suggested naming pattern: `[Feature]StorageAdapter` (e.g., `CacheStorageAdapter`)
   - Document the old and new name mapping
   - Keep a checklist of files to update

4. **Safe Renaming Process**
   For each StorageAdapter class:
   a. Rename the class definition first
   b. Update direct references in the same file
   c. Run the specific tests for that file
   d. Update references in related files one at a time
   e. Run affected tests after each file update
   f. Document any test failures for investigation

5. **Testing Strategy**
   - Run tests in isolation for each changed file
   - Use `--fail-fast` flag to catch issues early
   - Keep test runs focused on affected components
   - Document any unexpected test failures

6. **Verification Steps**
   - Create a comprehensive test checklist
   - Verify each renamed class in isolation
   - Check for any remaining references to old names
   - Run the full test suite only after all changes are complete

7. **Review and Merge Process**
   - Self-review the changes for consistency
   - Run final full test suite
   - Create detailed PR with the renaming changes
   - Merge this branch before proceeding with Rubocop fixes

## Important Safety Measures
- Always commit changes after successfully updating each file
- Keep a log of all changes made and their effects
- If agent crashes occur, revert to the last known good commit
- Take breaks between major changes to prevent confusion

## Workflow

1. **Initial Setup**
   ```