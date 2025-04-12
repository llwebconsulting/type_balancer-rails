# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Balanced Collection Integration' do
  let(:redis_strategy) { TypeBalancer::Rails::Strategies::RedisStrategy.new }

  # Verify positions are stored in Redis
  it 'stores positions in Redis' do
    key = TypeBalancer::Rails::Strategies::RedisStrategy.new.send(
      :generate_key, 
      Post.all
    )
    expect(redis_client.get(key)).not_to be_nil
  end
end
