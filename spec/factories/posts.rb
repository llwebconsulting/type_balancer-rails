FactoryBot.define do
  factory :post do
    sequence(:title) { |n| "Post Title #{n}" }
    sequence(:content) { |n| "Post Content #{n}" }
  end
end
