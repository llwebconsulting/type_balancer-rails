# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext'
require 'active_record'
require 'type_balancer'

require_relative 'type_balancer/rails/version'
require_relative 'type_balancer/rails'
require 'type_balancer/rails/collection_methods'

require 'type_balancer/rails/railtie' if defined?(Rails)
