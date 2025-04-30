# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

# Example App for type_balancer_rails

## Idiomatic Usage

The preferred way to configure type balancing in your Rails models is:

```ruby
class Post < ApplicationRecord
  balance_by_type :media_type
end
```

This is the most Rails-like and concise way to set the type field for balancing. The hash form (`balance_by_type type_field: :media_type`) is also supported for advanced options, but the above is recommended for most cases.

---

(Continue with other documentation as needed)
