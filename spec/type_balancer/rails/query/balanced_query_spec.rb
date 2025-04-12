# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Query::BalancedQuery do
  let(:model_class) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'posts'
      
      def self.column_names
        ['id', 'title', 'media_type']
      end
    end
  end

  let(:base_scope) { model_class.all }
  let(:default_options) { { type_field: :media_type } }
  
  subject(:query) { described_class.new(base_scope, default_options) }

  describe '#initialize' do
    context 'with scope' do
      it 'accepts an ActiveRecord::Relation' do
        expect { described_class.new(base_scope) }.not_to raise_error
      end

      it 'accepts a hash with :collection key' do
        expect {
          described_class.new({ collection: base_scope })
        }.not_to raise_error
      end

      it 'raises error for invalid scope' do
        expect {
          described_class.new('invalid')
        }.to raise_error(ArgumentError, 'Scope must be an ActiveRecord::Relation')
      end
    end

    context 'with options' do
      it 'merges with default options' do
        query = described_class.new(base_scope, order: :desc)
        expect(query.options).to include(
          order: :desc,
          conditions: {},
          type_field: nil
        )
      end
    end
  end

  describe '#build' do
    it 'validates the query' do
      expect(query).to receive(:validate!)
      query.build
    end

    it 'applies type field' do
      expect(query).to receive(:apply_type_field)
      query.build
    end

    it 'applies order' do
      expect(query).to receive(:apply_order)
      query.build
    end

    it 'applies conditions' do
      expect(query).to receive(:apply_conditions)
      query.build
    end

    it 'returns the modified scope' do
      expect(query.build).to be_a(ActiveRecord::Relation)
    end

    context 'with order option' do
      let(:ordered_scope) { instance_double(ActiveRecord::Relation) }

      before do
        allow(base_scope).to receive(:order).and_return(ordered_scope)
      end

      it 'applies string order' do
        query = described_class.new(base_scope, default_options.merge(order: 'desc'))
        query.build
        expect(base_scope).to have_received(:order).with('desc')
      end

      it 'applies symbol order' do
        query = described_class.new(base_scope, default_options.merge(order: :desc))
        query.build
        expect(base_scope).to have_received(:order).with('desc')
      end

      it 'applies array order' do
        query = described_class.new(base_scope, default_options.merge(order: [:desc, :asc]))
        query.build
        expect(base_scope).to have_received(:order).with(['desc', 'asc'])
      end

      it 'applies hash order' do
        query = described_class.new(base_scope, default_options.merge(order: { created_at: :desc }))
        query.build
        expect(base_scope).to have_received(:order).with({ created_at: 'desc' })
      end

      it 'raises error for invalid order format' do
        query = described_class.new(base_scope, default_options.merge(order: 123))
        expect { query.build }.to raise_error(ArgumentError, 'Invalid order format')
      end
    end

    context 'with conditions' do
      let(:filtered_scope) { instance_double(ActiveRecord::Relation) }

      before do
        allow(base_scope).to receive(:where).and_return(filtered_scope)
      end

      it 'applies conditions to scope' do
        conditions = { status: 'published' }
        query = described_class.new(base_scope, default_options.merge(conditions: conditions))
        query.build
        expect(base_scope).to have_received(:where).with(conditions)
      end
    end
  end

  describe '#with_options' do
    it 'returns a new query instance' do
      new_query = query.with_options(order: :desc)
      expect(new_query).to be_a(described_class)
      expect(new_query).not_to eq(query)
    end

    it 'merges new options with existing ones' do
      new_query = query.with_options(order: :desc)
      expect(new_query.options).to include(
        order: :desc,
        type_field: :media_type
      )
    end
  end

  describe 'type field inference' do
    context 'when type field is not specified' do
      subject(:query) { described_class.new(base_scope) }

      it 'infers from common field names' do
        expect(query.build.scope).to eq(base_scope)
      end

      context 'when no common fields exist' do
        let(:model_class) do
          Class.new(ActiveRecord::Base) do
            self.table_name = 'posts'
            def self.column_names
              ['id', 'title']
            end
          end
        end

        it 'raises an error' do
          expect { query.build }.to raise_error(
            ArgumentError,
            'No type field found. Please specify one using type_field: :your_field'
          )
        end
      end
    end
  end
end 