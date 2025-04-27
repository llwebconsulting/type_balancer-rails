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

## Usage

To balance records by a given type field, use the following syntax:

```ruby
Post.balance_by_type(type_field: :media_type)
Content.balance_by_type(type_field: :category)
```

> **Note:** Passing a symbol directly (e.g., `balance_by_type(:media_type)`) is not currently supported. Always use the options hash syntax as shown above.

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
