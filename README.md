# TypeBalancer Rails

A Ruby on Rails gem for balancing records by type in ActiveRecord collections.

[![Gem Version](https://badge.fury.io/rb/type_balancer-rails.svg)](https://badge.fury.io/rb/type_balancer-rails)
[![Build Status](https://github.com/your-username/type_balancer-rails/workflows/CI/badge.svg)](https://github.com/your-username/type_balancer-rails/actions)
[![Code Climate](https://codeclimate.com/github/your-username/type_balancer-rails/badges/gpa.svg)](https://codeclimate.com/github/your-username/type_balancer-rails)

## Features

- Balance ActiveRecord collections by type field
- Multiple storage strategies (Redis, Cursor)
- Built-in caching support
- Flexible pagination
- Thread-safe operations
- Rails integration

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'type_balancer-rails'
```

Then execute:

```bash
$ bundle install
```

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

## Custom Storage Strategies

Create your own storage strategy:

```ruby
module TypeBalancer
  module Rails
    module Storage
      class CustomStorage < BaseStorage
        def store(key, value, ttl: nil)
          # Implementation
        end

        def fetch(key)
          # Implementation
        end

        def delete(key)
          # Implementation
        end

        def clear
          # Implementation
        end
      end
    end
  end
end
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

## Migration Guide

If you're upgrading from an older version, please check our [Migration Guide](docs/migration_guide.md).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b feature/my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/my-new-feature`)
5. Create new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TypeBalancer Rails project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](CODE_OF_CONDUCT.md).
