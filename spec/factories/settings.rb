FactoryBot.define do
  factory :setting do
    default_variations { 5 }
    default_aspect_ratio { "16:9" }
  end
end
