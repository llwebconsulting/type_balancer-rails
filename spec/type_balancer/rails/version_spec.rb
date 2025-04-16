# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails do
  describe 'VERSION' do
    it 'has a version number' do
      expect(TypeBalancer::Rails::VERSION).not_to be_nil
    end

    it 'follows semantic versioning format' do
      expect(TypeBalancer::Rails::VERSION).to match(/^\d+\.\d+\.\d+(?:-[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?(?:\+[0-9A-Za-z-]+)?$/)
    end

    it 'is a frozen string' do
      expect(TypeBalancer::Rails::VERSION).to be_frozen
    end

    it 'cannot be modified' do
      expect do
        TypeBalancer::Rails::VERSION << '.modified'
      end.to raise_error(FrozenError)
    end
  end
end
