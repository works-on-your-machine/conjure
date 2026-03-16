FactoryBot.define do
  factory :conjuring do
    project
    grimoire_text { "VHS static. CRT monitors with scan lines." }
    variations_count { 5 }
    status { :pending }
  end
end
