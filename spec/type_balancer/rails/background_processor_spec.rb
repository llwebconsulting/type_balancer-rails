# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::BackgroundProcessor do
  describe '.should_process_async?' do
    context 'when Rails configuration is available' do
      let(:rails_config) { double('Rails.configuration') }
      let(:type_balancer_config) { double('type_balancer_config') }

      before do
        stub_const('Rails', double('Rails', configuration: rails_config))
        allow(rails_config).to receive(:type_balancer).and_return(type_balancer_config)
      end

      context 'with custom async threshold' do
        before do
          allow(type_balancer_config).to receive(:async_threshold).and_return(500)
        end

        it 'returns true when collection size exceeds threshold' do
          expect(described_class.should_process_async?(501)).to be true
        end

        it 'returns false when collection size is below threshold' do
          expect(described_class.should_process_async?(499)).to be false
        end

        it 'returns false when collection size equals threshold' do
          expect(described_class.should_process_async?(500)).to be false
        end
      end

      context 'without custom async threshold' do
        before do
          allow(type_balancer_config).to receive(:async_threshold).and_return(nil)
        end

        it 'uses default threshold (1000)' do
          expect(described_class.should_process_async?(1001)).to be true
          expect(described_class.should_process_async?(999)).to be false
        end
      end
    end

    context 'when Rails configuration is not available' do
      before do
        hide_const('Rails')
      end

      it 'uses default threshold' do
        expect(described_class.should_process_async?(1001)).to be true
        expect(described_class.should_process_async?(999)).to be false
      end
    end
  end
end 