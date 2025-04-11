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

### 3. Caching Infrastructure

#### Database Structure

```ruby
create_table :type_balancer_balanced_positions do |t|
  t.references :record, polymorphic: true, null: false
  t.integer :position, null: false
  t.string :cache_key, null: false
  t.string :type_field
  t.timestamps

  t.index [:cache_key, :position], unique: true
  t.index [:record_type, :record_id, :cache_key], unique: true
end
```

#### Caching Strategy

```ruby
module TypeBalancer
  module Rails
    class BalancedCollectionQuery
      def fetch_or_calculate_positions
        Rails.cache.fetch(cache_key, expires_in: 1.hour) do
          calculate_and_store_positions
        end
      end

      private

      def cache_key
        base = "type_balancer/#{@scope.model_name.plural}"
        scope_key = @scope.cache_key_with_version
        options_key = Digest::MD5.hexdigest(@options.to_json)
        "#{base}/#{scope_key}/#{options_key}"
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

#### 2. Position Storage

```ruby
module TypeBalancer
  module Rails
    class BalancedPosition < ApplicationRecord
      belongs_to :record, polymorphic: true
      
      validates :position, presence: true
      validates :cache_key, presence: true
      
      scope :for_collection, ->(cache_key) { where(cache_key: cache_key) }
    end
  end
end
```

#### 3. Cache Invalidation

```ruby
module TypeBalancer
  module Rails
    module CacheInvalidation
      extend ActiveSupport::Concern

      included do
        after_commit :invalidate_balance_cache
      end

      private

      def invalidate_balance_cache
        Rails.cache.delete("type_balancer/#{self.class.name.underscore.pluralize}/#{cache_key_with_version}")
        BalancedPosition.where(record: self).delete_all
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
rails db:migrate
```

### Configuration

```ruby
# config/initializers/type_balancer.rb
TypeBalancer::Rails.configure do |config|
  config.cache_duration = 1.hour
  config.async_threshold = 1000  # Use background job for collections larger than this
  config.per_page_default = 25
  config.max_per_page = 100
end
```

## Performance Considerations

1. **Cached Position Storage**
   - Positions stored in dedicated table
   - Indexed for fast retrieval
   - Cache invalidation on record updates

2. **Pagination Optimization**
   - Uses window functions for efficient pagination
   - Maintains balanced order across pages
   - Minimizes database queries

3. **Background Processing**
   - Automatic for large collections
   - Progress tracking
   - Cache warming

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