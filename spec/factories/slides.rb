FactoryBot.define do
  factory :slide do
    title { "Title card" }
    description { "Talk title with dramatic presentation." }
    sequence(:position) { |n| n }
    project
  end
end
