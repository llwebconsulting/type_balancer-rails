# frozen_string_literal: true

require 'spec_helper'
require 'type_balancer/rails/configuration/pagination_config'

module TypeBalancer
  module Rails
    class Configuration
      RSpec.describe PaginationConfig do
        describe '#initialize' do
          context 'with default values' do
            subject(:config) { described_class.new }

            it 'sets default max_per_page' do
              expect(config.max_per_page).to eq(100)
            end

            it 'sets default cursor_buffer_multiplier' do
              expect(config.cursor_buffer_multiplier).to eq(1.5)
            end
          end

          context 'with custom values' do
            subject(:config) { described_class.new(max_per_page: 50, cursor_buffer_multiplier: 2.0) }

            it 'sets custom max_per_page' do
              expect(config.max_per_page).to eq(50)
            end

            it 'sets custom cursor_buffer_multiplier' do
              expect(config.cursor_buffer_multiplier).to eq(2.0)
            end
          end
        end

        describe '#set_max_per_page' do
          subject(:config) { described_class.new }

          context 'with valid value' do
            it 'updates max_per_page' do
              config.set_max_per_page(50)
              expect(config.max_per_page).to eq(50)
            end

            it 'converts string values to integers' do
              config.set_max_per_page('75')
              expect(config.max_per_page).to eq(75)
            end
          end

          context 'with invalid value' do
            it 'ignores negative values' do
              config.set_max_per_page(-10)
              expect(config.max_per_page).to eq(100)
            end

            it 'ignores zero' do
              config.set_max_per_page(0)
              expect(config.max_per_page).to eq(100)
            end
          end
        end

        describe '#set_buffer_multiplier' do
          subject(:config) { described_class.new }

          context 'with valid value' do
            it 'updates cursor_buffer_multiplier' do
              config.set_buffer_multiplier(2.5)
              expect(config.cursor_buffer_multiplier).to eq(2.5)
            end

            it 'converts string values to floats' do
              config.set_buffer_multiplier('3.0')
              expect(config.cursor_buffer_multiplier).to eq(3.0)
            end
          end

          context 'with invalid value' do
            it 'ignores values less than or equal to 1.0' do
              config.set_buffer_multiplier(1.0)
              expect(config.cursor_buffer_multiplier).to eq(1.5)

              config.set_buffer_multiplier(0.5)
              expect(config.cursor_buffer_multiplier).to eq(1.5)
            end
          end
        end

        describe '#reset!' do
          subject(:config) { described_class.new(max_per_page: 50, cursor_buffer_multiplier: 2.0) }

          it 'resets all values to defaults' do
            config.reset!
            expect(config.max_per_page).to eq(100)
            expect(config.cursor_buffer_multiplier).to eq(1.5)
          end
        end
      end
    end
  end
end 