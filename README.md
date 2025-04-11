# TypeBalancer Rails

Rails integration for the TypeBalancer gem, providing efficient pagination strategies for balanced type collections.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'type_balancer-rails'
```

And then execute:

```bash
$ bundle install
```

## Configuration

Configure TypeBalancer Rails in an initializer:

```ruby
# config/initializers/type_balancer.rb
TypeBalancer::Rails.configure do |config|
  # Choose your storage strategy (:cursor or :redis)
  config.storage_strategy = :cursor

  # Cursor strategy settings
  config.cursor_buffer_multiplier = 3  # Fetch buffer size multiplier

  # Redis strategy settings (if using Redis)
  # config.redis = Redis.new(url: ENV['REDIS_URL'])
  # config.redis_ttl = 1.hour
end
```

## Usage

### Basic Usage

```ruby
class Post < ApplicationRecord
  # Define which field to balance by
  def self.feed
    balance_by_type(:media_type)
  end
end

# In your controller
@posts = Post.feed.page(params[:page]).per(20)
```

### Storage Strategies

#### Cursor Strategy (Default)

The cursor strategy is memory-efficient and ideal for real-time data. It doesn't require any additional dependencies.

**Advantages:**
- No additional dependencies
- No storage overhead
- Consistent results even with data changes
- Excellent for real-time data
- Memory efficient

**Trade-offs:**
- Fetches more records than needed (configurable buffer)
- No "total pages" count
- Forward-only pagination

#### Redis Strategy

The Redis strategy is ideal for high-traffic applications where caching balanced results improves performance.

**Advantages:**
- Cached results
- Bidirectional pagination
- Total pages available
- Consistent ordering across page loads

**Trade-offs:**
- Redis dependency
- Additional memory usage
- Potentially stale data
- Cache invalidation complexity

### Pagination

Works with standard pagination methods:

```ruby
# Basic pagination
@posts = Post.feed.page(2).per(20)

# Check for next page
@posts.next_page?

# Get total pages (Redis strategy only)
@posts.total_pages if @posts.respond_to?(:total_pages)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/llwebconsulting/type_balancer-rails.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
