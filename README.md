# TypeBalancer::Rails

Rails integration for the TypeBalancer gem, providing ActiveRecord integration, efficient caching, and pagination support.

## Features

- **ActiveRecord Integration**: Easy type balancing with a clean DSL
- **Pagination Support**: Works with Kaminari and will_paginate
- **Caching Infrastructure**: Efficient position caching with proper invalidation
- **Background Processing**: Handles large collections asynchronously

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'type_balancer-rails'
```

Then execute:

```bash
$ bundle install
$ rails generate type_balancer:install
$ rails db:migrate
```

## Usage

### Basic Usage

```ruby
class Post < ApplicationRecord
  include TypeBalancer::Rails::CacheInvalidation
  
  # Optional: Configure default type field
  balance_by_type on: :media_type
end

# In your controller
@posts = Post.balance_by_type.page(params[:page])

# With custom type field
@posts = Post.balance_by_type(field: :category)

# With custom type order
@posts = Post.balance_by_type(order: [:video, :image, :article])

# With pagination options
@posts = Post.balance_by_type.page(3).per(20)
```

### Configuration

Configure TypeBalancer::Rails in `config/initializers/type_balancer.rb`:

```ruby
TypeBalancer::Rails.configure do |config|
  # Duration to cache balanced positions
  config.cache_duration = 1.hour

  # Collection size threshold for background processing
  config.async_threshold = 1000

  # Default number of items per page
  config.per_page_default = 25

  # Maximum number of items per page
  config.max_per_page = 100
end
```

### Cache Invalidation

Include the `CacheInvalidation` module in your models to automatically invalidate cached positions when records change:

```ruby
class Post < ApplicationRecord
  include TypeBalancer::Rails::CacheInvalidation
end
```

### Background Processing

Large collections are automatically processed in the background when they exceed the `async_threshold`. Progress can be monitored through ActionCable:

```javascript
// app/javascript/channels/type_balancer_channel.js
import consumer from "./consumer"

consumer.subscriptions.create("TypeBalancerChannel", {
  received(data) {
    if (data.status === "completed") {
      // Refresh your view
    }
  }
})
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/llwebconsulting/type_balancer-rails.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
