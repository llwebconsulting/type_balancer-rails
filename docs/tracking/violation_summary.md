# RuboCop Violation Summary

## Configuration Warnings
- Plugin syntax needs updating in `.rubocop.yml` for:
  - rubocop-rails
  - rubocop-capybara
  - rubocop-factory_bot

## Metrics Violations
1. ✓ `lib/type_balancer/rails/query/pagination_service.rb`: - FIXED
   - AbcSize: `paginate` method - Resolved by extracting logic into smaller methods
   - MethodLength: `paginate` method - Resolved by breaking down into focused methods

2. Module Length Issues (Not Auto-correctable):
   - `spec/type_balancer/rails/configuration_facade_spec.rb` (227/200 lines)
   - `spec/type_balancer/rails/query/pagination_service_spec.rb` (269/200 lines)

## ✓ RSpec Violations (Fixed)
All in `spec/type_balancer/rails/query/pagination_service_spec.rb`:
- Multiple `receive_messages` violations (13 instances) - FIXED
  - Lines: 70-71, 81-82, 133-134, 151-152, 163-164, 189-191
  - All instances have been auto-corrected to use `receive_messages`

## ✓ Layout Violations (Fixed)
- Line Length issues in `spec/type_balancer/rails/query/pagination_service_spec.rb` - FIXED
  - Broke up long method chains into multiple lines
  - Split `receive_messages` arguments across multiple lines

## Summary Statistics
- Total files inspected: 80
- Remaining violations: 2
- Auto-correctable: 0
- Manual fixes needed: 2

## Violation Distribution
- Metrics: 2 violations (Module Length only)

## Next Steps (per plan)
1. ✓ Fix auto-correctable RSpec violations (13 instances of `receive_messages`) - COMPLETED
2. ✓ Address line length issues in pagination service spec - COMPLETED
3. ✓ Fix `paginate` method metrics violations - COMPLETED
4. Address remaining module length issues:
   - Plan approach for breaking up large spec files
   - Consider extracting shared examples or contexts 