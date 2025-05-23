# TypeBalancer Rails

[![Gem Version](https://badge.fury.io/rb/type_balancer_rails.svg)](https://badge.fury.io/rb/type_balancer_rails)
[![Build Status](https://github.com/llwebconsulting/type_balancer-rails/workflows/CI/badge.svg)](https://github.com/llwebconsulting/type_balancer-rails/actions)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Rails integration for the [TypeBalancer](https://github.com/llwebconsulting/type_balancer) gem. This gem provides a seamless way to balance content types in your Rails application's ActiveRecord queries.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'type_balancer_rails'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install type_balancer_rails
```

## Caching and Performance

Type balancing can be computationally expensive, especially on large datasets. To ensure efficient performance, **TypeBalancer Rails automatically caches the balanced ID list for each query**. This means:
- The balancing algorithm only runs when needed (on cache miss or reset).
- Subsequent requests for the same query use the cached result, reducing database and CPU load.
- Caching is essential for production use. Disabling or misconfiguring cache may result in slow queries.

**Adjust cache settings thoughtfully:**
- Shorter expiries mean fresher data but more frequent recalculation.
- Longer expiries improve performance but may serve stale results if your data changes often.

## Configuration

To customize caching and performance, use the Rails-style configuration block in an initializer (e.g., `config/initializers/type_balancer.rb`):

```ruby
TypeBalancer::Rails.configure do |config|
  # Use the default cache adapter (backed by Rails.cache)
  config.cache_adapter = TypeBalancer::Rails::CacheAdapter.new

  # Set the global cache expiry (in seconds)
  # Default is 600 (10 minutes). Adjust as needed for your app's freshness/performance needs.
  config.cache_expiry_seconds = 600
end
```

> **Note:** You can also set these options directly
> ```ruby
> TypeBalancer::Rails.cache_adapter = TypeBalancer::Rails::CacheAdapter.new
> TypeBalancer::Rails.cache_expiry_seconds = 600
> ```

## Usage

To balance records by a given type field, use the following syntax:

```ruby
Post.balance_by_type(type_field: :media_type)
Content.balance_by_type(type_field: :category)
```

> **Note:** Passing a symbol directly (e.g., `balance_by_type(:media_type)`) is not currently supported. Always use the options hash syntax as shown above.

> **Note:** Type field values are automatically converted to strings, so you don't need to handle string conversion manually. For example, both `:article` and `"article"` as type values will work correctly.

### Basic Usage

The gem adds a `balance_by_type` method to your ActiveRecord relations. Here's how to use it:

```ruby
# Get a balanced collection of posts
@posts = Post.all.balance_by_type

# With pagination
@posts = Post.all.balance_by_type.page(2).per(20)

# Specify a custom type field
@posts = Post.all.balance_by_type(type_field: :content_type)
```

### Model Configuration

You can configure the default type field at the model level:

```ruby
class Post < ApplicationRecord
  balance_by_type type_field: :content_type
end

# Now you can call without specifying the type field
@posts = Post.all.balance_by_type

# You can still override the type field per query
@posts = Post.all.balance_by_type(type_field: :category)
```

### Chainable with ActiveRecord

The `balance_by_type` method preserves the ActiveRecord query interface:

```ruby
@posts = Post.where(published: true)
             .order(created_at: :desc)
             .balance_by_type
             .page(2)
             .per(20)
```

### Pagination and Caching (Always Enabled)

Results from `balance_by_type` are **always paginated** for performance reasons. By default, only the first 20 balanced records are returned. You can control the page size and which page is returned using the `per_page` and `page` options:

```ruby
# Get the first 20 balanced records (default)
@posts = Post.all.balance_by_type

# Get the second page of 10 balanced records
@posts = Post.all.balance_by_type(type_field: :category, per_page: 10, page: 2)
```

- **Default page size:** 20
- **Default page:** 1
- **Pagination is required:** There is no option to disable pagination. This is necessary for performance, especially on large datasets.

#### Cache Expiration

Balanced results are cached by default for 10 minutes to improve performance and reduce redundant calculations. You can override the cache expiration for a specific call by passing the `expires_in` option:

```ruby
# Cache the balanced results for 1 hour instead of 10 minutes
@posts = Post.all.balance_by_type(type_field: :category, expires_in: 1.hour)
```

- **Default cache expiration:** 10 minutes
- **Custom cache expiration:** Pass `expires_in: ...` (e.g., `expires_in: 1.hour`)

> **Note:** If you need to retrieve all balanced records, you must manually iterate through all pages.

### Per-request Cache Control

You can override cache behavior for a single call to `balance_by_type`:

- **Custom Expiry:**
  ```ruby
  # Cache the balanced results for 1 hour for this request only
  @posts = Post.all.balance_by_type(type_field: :category, expires_in: 1.hour)
  ```
- **Force Cache Reset:**
  ```ruby
  # Force recalculation and cache update for this request
  @posts = Post.all.balance_by_type(type_field: :category, cache_reset: true)
  ```

#### Controller Example

You can pass these options from controller params:

```ruby
class PostsController < ApplicationController
  def index
    @posts = Post.all.balance_by_type(
      type_field: params[:type_field],
      expires_in: params[:expires_in],
      cache_reset: params[:cache_reset].present?
    )
  end
end
```

## Cache Management and Isolation

- **Cache keys are unique per model and type field.**
- There is no cross-contamination between different models or type fields.
- If you use multiple type fields or models, each will have its own cache entry.
- To avoid stale data, clear the cache after bulk updates or schema changes using `TypeBalancer::Rails.clear_cache!`.

## Upgrade Notes

- `balance_by_type` now supports per-request `expires_in` and `cache_reset` options.
- Global cache expiry is configurable via `TypeBalancer::Rails.cache_expiry_seconds`.
- You can clear all cached results with `TypeBalancer::Rails.clear_cache!`.
- Caching is always enabled and required for performance.
- Pagination is always enabled; you must page through results if you want all records.

## Planned Enhancements

- Support for passing a symbol directly to `balance_by_type`, e.g., `balance_by_type(:media_type)`, for more ergonomic usage. This is planned for a future version.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Bug reports and pull requests are welcome on GitHub at https://github.com/llwebconsulting/type_balancer-rails.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TypeBalancer Rails project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](CODE_OF_CONDUCT.md).
