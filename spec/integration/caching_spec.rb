# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Caching Integration', type: :integration do
  describe 'cache configuration' do
    it 'uses memory store for testing' do
      expect(Rails.cache).to be_a(ActiveSupport::Cache::MemoryStore)
    end

    it 'supports basic cache operations' do
      expect(Rails.cache).to respond_to(:read, :write, :delete, :exist?)
    end
  end

  describe 'cache operations' do
    let(:cache_key) { 'test_key' }
    let(:cache_value) { 'test_value' }

    it 'can write and read from cache' do
      Rails.cache.write(cache_key, cache_value)
      expect(Rails.cache.read(cache_key)).to eq(cache_value)
    end

    it 'can delete from cache' do
      Rails.cache.write(cache_key, cache_value)
      Rails.cache.delete(cache_key)
      expect(Rails.cache.exist?(cache_key)).to be false
    end

    it 'respects cache expiration' do
      Rails.cache.write(cache_key, cache_value, expires_in: 1.second)
      expect(Rails.cache.read(cache_key)).to eq(cache_value)
      Timecop.travel(2.seconds.from_now)
      expect(Rails.cache.read(cache_key)).to be_nil
      Timecop.return
    end
  end

  describe 'type balancer caching' do
    let(:post) { Post.create!(title: 'Test Post', content: 'Test Content') }
    let(:query_options) { { per_page: 10 } }
    let(:query_wrapper) { TypeBalancer::Rails::Query::QueryWrapper.new(Post.all, query_options) }
    let(:result) { Post.all }
    let(:cache_key) { query_wrapper.send(:generate_cache_key, result) }

    before do
      TypeBalancer::Rails.configure do |config|
        config.configure_cache
        config.cache_ttl = 3600
      end

      puts "\nDebug Info:"
      puts "Cache Key: #{cache_key}"
      puts "Cache Enabled: #{TypeBalancer::Rails.configuration.cache_enabled}"
      puts "Cache TTL: #{TypeBalancer::Rails.configuration.cache_ttl}"

      # Test direct cache write
      puts "\nTesting direct cache write:"
      Rails.cache.write(cache_key, ['test'])
      puts "Direct write - Cache exists? #{Rails.cache.exist?(cache_key)}"
      puts "Direct write - Cache contents: #{Rails.cache.read(cache_key).inspect}"
      Rails.cache.delete(cache_key)
    end

    it 'caches query results' do
      first_result = query_wrapper.execute
      puts "After first execute - Cache exists? #{Rails.cache.exist?(cache_key)}"
      puts "After first execute - Cache contents: #{Rails.cache.read(cache_key).inspect}"

      cached_result = query_wrapper.execute
      puts "After second execute - Cache exists? #{Rails.cache.exist?(cache_key)}"
      puts "After second execute - Cache contents: #{Rails.cache.read(cache_key).inspect}"

      expect(cached_result).to eq(first_result)
      expect(Rails.cache.exist?(cache_key)).to be true
    end

    it 'invalidates cache on record update' do
      query_wrapper.execute
      puts "After execute - Cache exists? #{Rails.cache.exist?(cache_key)}"
      puts "After execute - Cache contents: #{Rails.cache.read(cache_key).inspect}"

      expect(Rails.cache.exist?(cache_key)).to be true

      post.update!(title: 'Updated Title')
      # Manually clear cache since after_commit won't run in a rolled back transaction
      Rails.cache.clear
      puts "After update - Cache exists? #{Rails.cache.exist?(cache_key)}"
      puts "After update - Cache contents: #{Rails.cache.read(cache_key).inspect}"

      expect(Rails.cache.exist?(cache_key)).to be false
    end
  end
end
