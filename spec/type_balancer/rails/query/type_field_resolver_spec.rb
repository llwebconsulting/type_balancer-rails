# frozen_string_literal: true

require 'spec_helper'

module TypeBalancer
  module Rails
    module Query
      RSpec.describe TypeFieldResolver do
        let(:model_class) do
          class_double(ActiveRecord::Base).tap do |double|
            allow(double).to receive(:column_names).and_return([])
          end
        end

        let(:scope) do
          double('ActiveRecord::Relation').tap do |double|
            allow(double).to receive(:respond_to?).with(:type_field).and_return(false)
            allow(double).to receive(:klass).and_return(model_class)
          end
        end

        let(:resolver) { described_class.new(scope) }

        describe '#initialize' do
          it 'stores the scope' do
            expect(resolver.scope).to eq(scope)
          end
        end

        describe '#resolve' do
          context 'with explicit field' do
            it 'returns the explicit field' do
              expect(resolver.resolve(:custom_type)).to eq(:custom_type)
            end
          end

          context 'when scope responds to type_field' do
            before do
              allow(scope).to receive(:respond_to?).with(:type_field).and_return(true)
              allow(scope).to receive(:type_field).and_return('model_type')
            end

            it 'returns the type_field from scope' do
              expect(resolver.resolve).to eq('model_type')
            end
          end

          context 'when inferring from column names' do
            TypeFieldResolver::COMMON_TYPE_FIELDS.each do |field|
              context "with #{field} in column names" do
                before do
                  allow(model_class).to receive(:column_names).and_return([field, 'other_column'])
                end

                it "infers #{field} as the type field" do
                  expect(resolver.resolve).to eq(field)
                end
              end
            end

            context 'with multiple common fields' do
              before do
                allow(model_class).to receive(:column_names)
                  .and_return(%w[type media_type other_column])
              end

              it 'uses the first matching field' do
                expect(resolver.resolve).to eq('type')
              end
            end
          end

          context 'when no field can be found' do
            it 'raises ArgumentError' do
              expect { resolver.resolve }
                .to raise_error(
                  ArgumentError,
                  'No type field found. Please specify one using type_field: :your_field'
                )
            end
          end

          context 'precedence order' do
            before do
              allow(scope).to receive(:respond_to?).with(:type_field).and_return(true)
              allow(scope).to receive(:type_field).and_return('model_type')
              allow(model_class).to receive(:column_names).and_return(['type'])
            end

            it 'prefers explicit field over type_field' do
              expect(resolver.resolve(:explicit_type)).to eq(:explicit_type)
            end

            it 'prefers type_field over inferred field' do
              expect(resolver.resolve).to eq('model_type')
            end
          end
        end
      end
    end
  end
end
