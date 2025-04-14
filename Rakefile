# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = "spec/**/*_spec.rb"
end

RuboCop::RakeTask.new

desc "Run all tests and checks"
task default: [:rubocop, :spec]

task :ci do
  ENV["COVERAGE"] = "true"
  Rake::Task["default"].invoke
end
