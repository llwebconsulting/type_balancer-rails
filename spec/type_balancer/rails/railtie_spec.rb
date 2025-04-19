# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Railtie do
  describe 'initialization' do
    let(:config) { instance_double('TypeBalancer::Rails::Configuration') }
    let(:active_record_base) { Class.new }

    before do
      allow(TypeBalancer::Rails).to receive(:configuration).and_return(config)
      allow(config).to receive(:register)
      allow(config).to receive(:storage_strategy=)
      allow(config).to receive(:cache_enabled=)
      allow(config).to receive(:cache_ttl=)

      # Mock ActiveSupport.on_load to execute the block in the context of active_record_base
      allow(ActiveSupport).to receive(:on_load).with(:active_record) do |_name, &block|
        active_record_base.class_eval(&block)
      end
    end

    it 'registers default strategies' do
      expect(config).to receive(:register).with(:cursor, TypeBalancer::Rails::Strategies::CursorStrategy)
      expect(config).to receive(:register).with(:redis, TypeBalancer::Rails::Strategies::RedisStrategy)

      described_class.instance.initializers.first.run
    end

    it 'sets default configuration values' do
      expect(config).to receive(:storage_strategy=).with(:cursor)
      expect(config).to receive(:cache_enabled=).with(true)
      expect(config).to receive(:cache_ttl=).with(3600)

      described_class.instance.initializers.first.run
    end

    it 'includes ActiveRecordExtension in ActiveRecord' do
      expect(active_record_base).to receive(:include).with(TypeBalancer::Rails::ActiveRecordExtension)

      described_class.instance.initializers.first.run
    end
  end
end
