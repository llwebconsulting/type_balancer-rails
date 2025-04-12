# Migration Guide

## Overview

This guide helps you migrate your application to the latest version of `type_balancer-rails`. The new version introduces several improvements:

- Better separation of concerns
- Enhanced caching capabilities
- More flexible storage options
- Improved pagination support

## Breaking Changes

### 1. Configuration Changes

The configuration interface has been simplified:

```ruby
# Old way
TypeBalancer::Rails.configure do |config|
  config.storage_strategy = :redis
  config.redis_client = Redis.new
end

# New way
TypeBalancer::Rails.configure do |config|
  config.storage_strategy = :redis
  config.configure_redis(Redis.new)
  config.cache_enabled = true
end
```

### 2. Pagination Methods

Some pagination methods have been renamed or enhanced:

```ruby
# Old way
posts = Post.balance_by_type.per_page(20)

# New way
posts = Post.balance_by_type.per(20)
```

New pagination features:
- `prev_page?` method
- `current_page` method
- Better integration with Kaminari and will_paginate

### 3. Storage Strategies

Storage strategies now support more features:

```ruby
# Redis storage with TTL
Post.balance_by_type(storage: :redis, ttl: 1.hour)

# Cursor storage with custom options
Post.balance_by_type(storage: :cursor, cursor_buffer_multiplier: 2)

# With caching enabled
Post.balance_by_type(storage: :redis, cache_enabled: true)
```

## Deprecation Warnings

The following features are deprecated and will be removed in the next major version:

1. `per_page` method - Use `per` instead
2. Direct strategy access - Use the configuration interface
3. Manual cache management - Use the new CacheDecorator

## Step-by-Step Migration

1. Update Configuration:
   ```ruby
   # config/initializers/type_balancer.rb
   TypeBalancer::Rails.configure do |config|
     config.storage_strategy = :redis
     config.configure_redis(Redis.new)
     config.cache_enabled = true
     config.cache_ttl = 1.hour
   end
   ```

2. Update Model Code:
   ```ruby
   class Post < ApplicationRecord
     # Old way
     # balance_by_type :media_type, strategy: :redis
     
     # New way
     balance_by_type :media_type, storage: :redis
   end
   ```

3. Update Pagination Code:
   ```ruby
   # Replace per_page calls
   @posts = Post.balance_by_type.per(20).page(params[:page])
   ```

4. Update Custom Storage:
   If you have custom storage strategies, they should now inherit from `TypeBalancer::Rails::Storage::BaseStorage`
   and implement the required interface.

## New Features

### 1. Enhanced Caching

The new version includes a powerful caching system:

```ruby
TypeBalancer::Rails.configure do |config|
  config.cache_enabled = true
  config.cache_ttl = 1.hour
  config.configure_cache(Rails.cache)
end
```

### 2. Better Type Field Detection

Automatic detection of type fields with configurable priorities:

```ruby
class Post < ApplicationRecord
  # Will automatically detect :media_type, :content_type, :type, or :category
  balance_by_type
end
```

### 3. Improved Error Handling

More descriptive error messages and validation:

```ruby
begin
  Post.balance_by_type(invalid_option: true)
rescue TypeBalancer::Rails::InvalidOptionError => e
  Rails.logger.error(e.message)
end
```

## Testing

Update your tests to use the new interfaces:

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

## Need Help?

If you encounter any issues during migration:

1. Check the [GitHub issues](https://github.com/your-username/type_balancer-rails/issues)
2. Join our [Discord community](https://discord.gg/your-invite)
3. Read the [full documentation](https://github.com/your-username/type_balancer-rails/docs) 