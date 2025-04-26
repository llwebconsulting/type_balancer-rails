# frozen_string_literal: true

module TestHelpers
  def create_relation_double
    double = instance_double(ActiveRecord::Relation)
    allow(double).to receive_messages(
      klass: Post,
      to_a: [],
      where: double,
      reorder: double
    )
    double
  end
end

RSpec.configure do |config|
  config.include TestHelpers
end
