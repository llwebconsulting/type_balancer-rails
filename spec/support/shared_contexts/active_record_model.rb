# frozen_string_literal: true

RSpec.shared_context 'active_record_model' do
  let(:model_class) do
    Class.new do
      def self.after_commit(*args, &block)
        @after_commit_blocks ||= []
        @after_commit_blocks << block if block_given?
      end

      def self.after_destroy(*args, &block)
        @after_destroy_blocks ||= []
        @after_destroy_blocks << block if block_given?
      end

      def self.validates(*args); end
      def self.validates_presence_of(*args); end
      def self.validates_uniqueness_of(*args); end
      def self.belongs_to(*args); end
      def self.has_many(*args); end
      def self.scope(*args); end
      def self.where(*args) = self
      def self.order(*args) = self
      def self.limit(*args) = self
      def self.offset(*args) = self
      def self.pluck(*args) = []
      def self.count(*args) = 0
      def self.find_by(*args) = nil
      def self.find_or_create_by(*args) = new
      def self.transaction(&block) = block.call

      def save! = true
      def save = true
      def destroy! = true
      def destroy = true
      def update!(*args) = true
      def update(*args) = true
      def reload = self
      def valid? = true
      def errors = []
      def id = 1
      def cache_key_with_version = 'test/1-123'
    end
  end
end
