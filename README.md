# TypeBalancer Rails Integration

Rails integration for the TypeBalancer gem.

[![Gem Version](https://badge.fury.io/rb/type_balancer_rails.svg)](https://badge.fury.io/rb/type_balancer_rails)
[![Build Status](https://github.com/carl/type_balancer_rails/workflows/CI/badge.svg)](https://github.com/carl/type_balancer_rails/actions)
[![Code Climate](https://codeclimate.com/github/carl/type_balancer_rails/badges/gpa.svg)](https://codeclimate.com/github/carl/type_balancer_rails)

## Features

- Balance ActiveRecord collections by type field
- Multiple storage strategies (Redis, Cursor)
- Built-in caching support with configurable TTL
- Flexible pagination
- Thread-safe operations
- Background processing for balance calculations
- Rails integration with automatic configuration
- SOLID design principles throughout

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'type_balancer_rails'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install type_balancer_rails

## Quick Start

1. Configure TypeBalancer in an initializer:

```ruby
# config/initializers/type_balancer.rb
TypeBalancer::Rails.configure do |config|
  # Use Redis storage (recommended for production)
  config.storage_strategy = :redis
  config.configure_redis(Redis.new)
  
  # Enable caching for better performance
  config.cache_enabled = true
  config.cache_ttl = 1.hour
  
  # Optional: Configure cursor buffer for in-memory storage
  config.cursor_buffer_multiplier = 2
end
```

2. Add to your models:

```ruby
class Post < ApplicationRecord
  balance_by_type :media_type
end
```

3. Use in your controllers:

```ruby
class PostsController < ApplicationController
  def index
    @posts = Post.balance_by_type.page(params[:page]).per(20)
  end
end
```

## Storage Strategies

### Redis Storage

Recommended for production environments:

```ruby
# Configure Redis
TypeBalancer::Rails.configure do |config|
  config.storage_strategy = :redis
  config.configure_redis(Redis.new(url: ENV['REDIS_URL']))
end

# Use in models
class Post < ApplicationRecord
  balance_by_type :media_type, storage: :redis, ttl: 1.hour
end
```

### Cursor Storage

Lightweight in-memory storage for development:

```ruby
# Configure cursor storage
TypeBalancer::Rails.configure do |config|
  config.storage_strategy = :cursor
  config.cursor_buffer_multiplier = 2
end

# Use in models
class Post < ApplicationRecord
  balance_by_type :media_type, storage: :cursor
end
```

## Caching

Enable caching for better performance:

```ruby
TypeBalancer::Rails.configure do |config|
  config.cache_enabled = true
  config.cache_ttl = 1.hour
  config.configure_cache(Rails.cache)
end
```

## Advanced Configuration

TypeBalancer Rails uses a unified configuration system under the `TypeBalancer::Rails::Config` namespace. This system is designed for flexibility and extensibility:

- All configuration logic is managed by `TypeBalancer::Rails::Config::Configuration`.
- You can extend or customize configuration by subclassing or including your own modules.
- Advanced users can interact directly with configuration components (e.g., `StrategyManager`, `PaginationConfig`) for custom strategies or behaviors.

Example (advanced):

```ruby
# Access the unified configuration class directly
config = TypeBalancer::Rails::Config::Configuration.new
config.storage_strategy = :memory
config.max_per_page = 50
# ...other advanced settings...
```

For most applications, the standard `TypeBalancer::Rails.configure` block is sufficient.

## Background Processing

TypeBalancer supports background processing for balance calculations:

```ruby
# Configure background processing
TypeBalancer::Rails.configure do |config|
  config.enable_background_processing = true
end

# Trigger background balance calculation
Post.calculate_balance_in_background
```

**Why use background processing?**

- For large collections, calculating balanced positions can be computationally expensive and may slow down web requests.
- Enabling background processing offloads this work to a background job (using ActiveJob), improving response times for users.
- This is especially useful for high-traffic applications or when balancing large datasets.

**Where are the results available?**

- Once the background job completes, the balanced positions are stored using your configured storage strategy (e.g., Redis or in-memory).
- When you next call `Post.balance_by_type`, the results will be fetched from storage, providing fast access to the balanced collection.
- You can monitor job status using your background job processor (e.g., Sidekiq, DelayedJob).

**Note:** If you request a balance before the background job completes, you may get stale or unbalanced results until the job finishes and updates the storage.

## Pagination

TypeBalancer supports flexible pagination:

```ruby
# Basic pagination
@posts = Post.balance_by_type.page(2).per(20)

# Check for more pages
@posts.next_page?
@posts.prev_page?

# Get total pages
@posts.total_pages

# Current page
@posts.current_page
```

## Testing

RSpec examples:

```ruby
RSpec.describe Post do
  describe '#balance_by_type' do
    it 'balances records by type' do
      posts = Post.balance_by_type
      expect(posts.per(10).page(1)).to be_a(TypeBalancer::Rails::TypeBalancerCollection)
    end
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/carl/type_balancer_rails. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/carl/type_balancer_rails/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TypeBalancer Rails project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/carl/type_balancer_rails/blob/main/CODE_OF_CONDUCT.md).
