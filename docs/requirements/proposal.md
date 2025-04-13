# TypeBalancer Rails Integration Proposal

## Overview

`type_balancer-rails` extends the core `type_balancer` gem with Rails-specific features, focusing on ActiveRecord integration, efficient caching, and pagination support.

## Key Features

### 1. ActiveRecord Integration

```ruby
class Post < ApplicationRecord
  balance_by_type on: :media_type
end

# Usage
Post.balance_by_type                    # Uses configured field
Post.published.balance_by_type          # Works with other scopes
Post.balance_by_type(field: :category)  # Override field
Post.balance_by_type(order: [:video, :image, :article])
```

### 2. Pagination Support

Seamless integration with Kaminari and will_paginate:

```ruby
# With Kaminari
Post.balance_by_type.page(3).per(20)

# With will_paginate
Post.balance_by_type.paginate(page: 3, per_page: 20)
```

### 3. Storage Strategies

#### Redis Strategy

```ruby
module TypeBalancer
  module Rails
    module Storage
      class RedisStorage < BaseStorage
        def store(key, value, ttl: nil)
          redis.set(key, serialize(value))
          redis.expire(key, ttl) if ttl
        end

        def fetch(key)
          if data = redis.get(key)
            deserialize(data)
          end
        end
      end
    end
  end
end
```

#### Cursor Strategy

```ruby
module TypeBalancer
  module Rails
    module Storage
      class CursorStorage < BaseStorage
        def store(key, value, ttl: nil)
          store_in_memory(key, value)
          schedule_cleanup(key, ttl) if ttl
        end

        def fetch(key)
          fetch_from_memory(key)
        end
      end
    end
  end
end
```

### 4. Background Processing

For large collections:

```ruby
class BalanceCalculationJob < ApplicationJob
  def perform(scope, options)
    positions = TypeBalancer.calculate_positions(scope, options)
    store_positions(positions)
    broadcast_completion
  end
end

# Usage
Post.balance_by_type(async: true)
```

## Implementation Details

### Core Classes

#### 1. Query Builder

```ruby
module TypeBalancer
  module Rails
    class BalancedCollectionQuery
      def initialize(scope, options = {})
        @scope = scope
        @options = options
        @cache_key = generate_cache_key
      end

      def page(num)
        positions = fetch_or_calculate_positions
        paginate_by_positions(positions, num)
      end

      private

      def paginate_by_positions(positions, page_num)
        page_positions = positions.slice(page_offset(page_num), page_size)
        @scope.where(id: page_positions.map(&:record_id))
              .order(Arel.sql("FIELD(id, #{page_positions.map(&:record_id).join(',')})"))
      end
    end
  end
end
```

### Installation

```ruby
# Gemfile
gem 'type_balancer-rails'

# Install
bundle install
rails generate type_balancer:install
```

### Configuration

```ruby
# config/initializers/type_balancer.rb
TypeBalancer::Rails.configure do |config|
  config.storage_strategy = :redis  # or :cursor
  config.configure_redis(Redis.new)
  config.cache_enabled = true
  config.cache_ttl = 1.hour
  config.per_page_default = 25
  config.max_per_page = 100
end
```

## Performance Considerations

1. **Efficient Storage Strategies**
   - Redis for distributed caching and persistence
   - Cursor strategy for lightweight, memory-efficient storage
   - Automatic cleanup of expired entries

2. **Pagination Optimization**
   - Uses window functions for efficient pagination
   - Maintains balanced order across pages
   - Cursor-based pagination for memory efficiency

## Future Enhancements

1. **GraphQL Integration**
   ```ruby
   field :posts, Types::PostType.connection_type do
     argument :balance_by, Types::PostBalanceInput
   end
   ```

2. **API Endpoints**
   ```ruby
   # Auto-generated endpoints for balanced collections
   resources :posts do
     get :balanced, on: :collection
   end
   ```

3. **View Helpers**
   ```ruby
   <%= balanced_collection @posts do |post| %>
     <%= render post %>
   <% end %>
   ```

## Development Roadmap

1. Phase 1: Core Integration
   - ActiveRecord integration
   - Basic caching
   - Pagination support

2. Phase 2: Performance
   - Background jobs
   - Cache optimization
   - Query optimization

3. Phase 3: Developer Experience
   - Generators
   - View helpers
   - Documentation

4. Phase 4: Advanced Features
   - GraphQL support
   - API endpoints
   - Custom balancing strategies 