# frozen_string_literal: true

require 'spec_helper'

module TypeBalancer
  module Rails
    module Strategies
      RSpec.describe MemoryStrategy do
        let(:collection) { double('TestCollection', object_id: 123) }
        let(:options) { {} }
        subject(:strategy) { described_class.new(collection, options) }

        describe '#initialize' do
          it 'creates an empty store' do
            expect(strategy.send(:instance_variable_get, :@store)).to eq({})
          end

          it 'sets the collection' do
            expect(strategy.collection).to eq(collection)
          end

          it 'sets the options' do
            expect(strategy.options).to eq(options)
          end
        end

        describe '#store' do
          let(:key) { 'test_key' }
          let(:value) { { data: 'test_value' } }

          it 'stores a value' do
            strategy.store(key, value)
            expect(strategy.fetch(key)).to eq(value)
          end

          context 'with invalid input' do
            it 'raises error when key is nil' do
              expect { strategy.store(nil, value) }.to raise_error(ArgumentError, 'Key cannot be nil')
            end

            it 'raises error when key is not a string or symbol' do
              expect { strategy.store(123, value) }.to raise_error(ArgumentError, 'Key must be a string or symbol')
            end

            it 'raises error when value is nil' do
              expect { strategy.store(key, nil) }.to raise_error(ArgumentError, 'Value cannot be nil')
            end
          end
        end

        describe '#fetch' do
          let(:key) { 'test_key' }
          let(:value) { { data: 'test_value' } }

          before do
            strategy.store(key, value)
          end

          it 'retrieves a stored value' do
            expect(strategy.fetch(key)).to eq(value)
          end

          it 'returns nil for non-existent key' do
            expect(strategy.fetch('non_existent')).to be_nil
          end

          it 'raises error when key is nil' do
            expect { strategy.fetch(nil) }.to raise_error(ArgumentError, 'Key cannot be nil')
          end
        end

        describe '#delete' do
          let(:key) { 'test_key' }
          let(:value) { { data: 'test_value' } }

          before do
            strategy.store(key, value)
          end

          it 'removes a stored value' do
            strategy.delete(key)
            expect(strategy.fetch(key)).to be_nil
          end

          it 'returns the deleted value' do
            expect(strategy.delete(key)).to eq(value)
          end

          it 'raises error when key is nil' do
            expect { strategy.delete(nil) }.to raise_error(ArgumentError, 'Key cannot be nil')
          end
        end

        describe '#clear' do
          before do
            strategy.store('key1', 'value1')
            strategy.store('key2', 'value2')
          end

          it 'removes all stored values' do
            strategy.clear
            expect(strategy.fetch('key1')).to be_nil
            expect(strategy.fetch('key2')).to be_nil
          end
        end

        describe '#clear_for_scope' do
          let(:scope) { double('Scope', object_id: 456) }
          
          before do
            strategy.store('key1', 'value1')
            strategy.store('key2', 'value2')
            strategy.store('key3', 'value3', scope: scope)
          end

          it 'removes only values matching the scope pattern' do
            strategy.clear_for_scope(scope)
            expect(strategy.fetch('key1')).not_to be_nil
            expect(strategy.fetch('key2')).not_to be_nil
            expect(strategy.fetch('key3')).to be_nil
          end
        end

        describe '#fetch_for_scope' do
          let(:scope) { double('Scope', object_id: 456) }
          
          before do
            strategy.store('key3', 'value3', scope: scope)
            strategy.store('key1', 'value1')
          end

          it 'returns only values matching the scope pattern' do
            result = strategy.fetch_for_scope(scope)
            expect(result.keys).to contain_exactly("type_balancer:#{scope.object_id}:key3")
            expect(result["type_balancer:#{scope.object_id}:key3"]).to eq('value3')
          end
        end
      end
    end
  end
end 