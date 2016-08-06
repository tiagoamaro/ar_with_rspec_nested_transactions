FactoryGirl.define do
  factory :post do
    sequence(:title) { |n| "Title #{n}" }
  end
end
