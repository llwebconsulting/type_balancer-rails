# frozen_string_literal: true

RSpec.shared_context 'with active record model' do
  let(:model_class) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Validations
      extend ActiveModel::Callbacks
      define_model_callbacks :commit, :destroy

      class << self
        def after_commit(*args, &block)
          set_callback(:commit, :after, *args, &block)
        end

        def after_destroy(*args, &block)
          set_callback(:destroy, :after, *args, &block)
        end

        def model_name
          ActiveModel::Name.new(self, nil, 'Post')
        end

        def table_name
          'posts'
        end

        def where(*_args)
          self
        end

        def order(*_args)
          self
        end

        def limit(*_args)
          self
        end

        def offset(*_args)
          self
        end

        def pluck(*_args)
          []
        end

        def count(*_args)
          0
        end

        def find_by(*_args)
          nil
        end

        def find_or_create_by(*_args)
          new
        end

        def transaction
          yield
        end

        def to_a
          []
        end
      end

      attr_accessor :id, :title, :media_type

      def initialize(attributes = {})
        super
        @id ||= 1
        @title ||= 'Test Post'
        @media_type ||= 'video'
      end

      def save!
        true
      end

      def save
        true
      end

      def destroy!
        run_callbacks :destroy do
          true
        end
      end

      def destroy
        destroy!
      end

      def update!(*_args)
        true
      end

      def update(*_args)
        true
      end

      def reload
        self
      end

      def cache_key_with_version
        "posts/#{id}-123"
      end
    end
  end
end
